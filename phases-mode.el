;;; phases-mode.el --- Display phases of a string given the time of the day -*- lexical-binding: t -*-

;; This file is part of the GNU Emacs package 'phases-mode'
;;
;; 'phases-mode.el' is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your option) any
;; later version.
;;
;; 'phases-mode.el' is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; Foobar. If not, see <https://www.gnu.org/licenses/>.
;;

;;; Commentary:

;; `phases-mode' is a [global] minor mode that displays strings according
;; to the time of the day (given the hour, minute and second).
;;
;;
;; Enable the global minor mode using `global-phases-mode' and the
;; minor mode using `phases-mode'.
;;
;; Install it by adding the following to your initialization file
;;
;;
;;; Code:


;;;; Variables:


(defvar phases-mode--use-timer t)


(defvar phases-mode-line-format '(:eval (phases-mode--mode-line-string))
  "Format string for moon phase in mode line.")


(defvar phases-mode--timer nil
  "Timer for \\[phases-mode].")


(defcustom phases-mode-repeat 30
  "Update the emoji clock after a delay of this amount of seconds."
  :group 'phases-mode
  :type '(integer))


(defvar phases-mode--moons
  '("🌑" "🌒" "🌓" "🌔"
    "🌕" "🌕" "🌕" "🌖"
    "🌗" "🌘""🌑""🌑" )
  "List of moon phase emojis.")


(defvar clock-phases
  '("🕛" "🕧" "🕐" "🕜" "🕑" "🕝"
    "🕒" "🕞" "🕓" "🕟" "🕔" "🕠"
    "🕕" "🕡" "🕖" "🕢" "🕗" "🕣"
    "🕘" "🕤" "🕙" "🕥" "🕚" "🕦")
  "Analog clock positions, incrementing in 30 min.")


(defcustom phases-mode-function #'phases-mode--clock-index
  "Function used to index `phases-mode-emojis'."
  :group 'phases-mode
  :type '(function))


(defcustom phases-mode-emojis clock-phases
  "Sequence to use with `phases-mode-function'."
  :group 'phases-mode
  :type '(list string))



;;;;  Indexing functions


(defun phases-mode--clock-index (clocks hour minute sec)
  "Return the right emoji in CLOCKS given HOUR, MINUTE & SEC.

Minutes are rounded to nearest half hour, invalid dates throw
error.

 - HOUR should be between 0 and 23.
 - MINUTE should be between 0 and 59."

  ;; Handle invalid dates.
  (if (not (and (>= 24 hour 0) (>= 60 minute 0)))
      (error "Invalid date %s:%s" hour minute)

    (let ((hour-index (* 2 (mod hour 12)))
          (half-hour (mod (round minute 30) 3)))
      (nth (+ half-hour hour-index) clocks))))


(defun phases-mode--moon-index (moons hour min sec)
  "Return the appropriate moon emoji in MOONS for a given HOUR (0-23),  MIN and SEC is not used."

  (let* ((i (/ 24 (length moons)))
         ;; Needed in-case the length of `phases-mode--moons' isn't equal to
         ;; `phases-mode--hours-count'.
         (phase-index (mod (/ hour i) (length moons))))
    ;; Index the string in `phases-mode--moons'.
    (nth phase-index moons)))


(cl-defun phases-mode--get-emoji (hour min sec)
  "Index an emoji in EMOJI-LIST given HOUR MIN and SEC.

`:index-fun' is the function for indexing EMOJI-LIST,
             it is given `:hour' `:min' `:sec' as
             arguments and returns the emoji string."

  (funcall phases-mode-function phases-mode-emojis
           hour min sec))


(defun phases-mode--mode-line-string ()
  "Return the moon phase string for the mode line."
  (let* ((time (decode-time (current-time)))
         (hour   (nth 2 time))
	       (minute (nth 1 time))
	       (second (nth 0 time)))
    (propertize (format "  %s %02d%02d"
                        (phases-mode--get-emoji hour minute second)
	                      hour
                        minute)
                        ;;second)
                'face 'mode-line)))




;;;; Clock Timer:


(defun phases-update-mode-line nil
  "Update moon state in mood-line."
  (when phases-mode
    (force-mode-line-update t)))


(defun phases-mode--start-timer nil
  "Start timer to update clock."
  (when phases-mode--use-timer
    (setq  phases-mode--timer
		       (run-with-timer 0 phases-mode-repeat
                           #'force-mode-line-update t))))


(defun phases-mode--stop-timer nil
  "Stop timer to update clock."
  (cancel-timer phases-mode--timer))



;;;; Start/Stop Clock:


(defun phases-mode--init nil
  "Initialize \\[phases-mode]."

  ;; Start idle timer and modify mode-line.
  (add-to-list 'mode-line-format phases-mode-line-format)
  (phases-mode--start-timer))


(defun phases-mode--stop nil
  "Stop \\[phases-mode]."
  ;; Cancel timer and remove from mode-line.

	(setq mode-line-format
        (remove phases-mode-line-format
                mode-line-format))

  (phases-mode--stop-timer))



;;;; Modes:


(define-minor-mode phases-mode
  "Minor mode to display moon phase in the mode line."
  :global t
  :init-value nil
  :group 'phases-mode
  :lighter "moon"

  (if phases-mode
      (phases-mode--init)
    (phases-mode--stop))

  (phases-update-mode-line))




(define-global-minor-mode global-phases-mode
  phases-mode  phases-mode
  :group 'phases-mode)


(provide 'phases-mode)
(provide 'global-phases-mode)


(provide 'phases-mode.el)
;;; phases-mode.el ends here
