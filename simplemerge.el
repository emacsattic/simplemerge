;;;    Copyright (C) 1999  Peter Österlund.
;;;
;;;    This program is free software; you can redistribute it and/or modify
;;;    it under the terms of the GNU General Public License as published by
;;;    the Free Software Foundation; either version 2 of the License, or
;;;    (at your option) any later version.
;;;
;;;    This program is distributed in the hope that it will be useful,
;;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;    GNU General Public License for more details.
;;;
;;;    You should have received a copy of the GNU General Public License
;;;    along with this program; if not, write to the Free Software
;;;    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;;
;;; Major mode to help resolving conflicts in output generated
;;; by the merge(1) or diff3(1) program.
;;;
;;; There are two modes of operation, "edit mode" and "fast mode".
;;; Fast mode is the default mode.
;;;
;;; The default key bindings in "fast mode" are as follows:
;;;
;;;    e   Switch to edit mode
;;;    f   Switch to fast mode
;;;    n   Jump to next conflict mark
;;;    p   Jump to previous conflict mark
;;;    b   Keep 'base' version in current conflict region
;;;    t   Keep 'theirs' version in current conflict region
;;;    y   Keep 'yours' version in current conflict region
;;;    k   Keep current version (the version at the current cursor location)
;;;        in current conflict region
;;;    u   Undo previous command
;;;    <   Diff 'base' and 'yours' version of current conflict region
;;;    >   Diff 'base' and 'theirs' version of current conflict region
;;;    :   Diff 'yours' and 'theirs' version of current conflict region
;;;    =   Delete other windows
;;;    l   Mark conflict regions
;;;    !   Remove all trivial conflicts, ie where yours and theirs are equal
;;;
;;; In "edit" mode, commands have to be prefixed by
;;; `simple-merge-command-prefix' (C-c by default).
;;;

(defvar simple-merge-version "1.4" "The simple-merge version number.")

(defvar simple-merge-command-prefix "\C-c"
  "Command prefix for merge commands in edit mode.")

(defvar simple-merge-basic-keymap nil)

(defvar simple-merge-edit-keymap nil
  "Keymap of simple-merge commands.
In `edit' mode, commands must be prefixed by \
\\<simple-merge-fast-keymap>\\[simple-merge-basic-keymap].")

(defvar simple-merge-fast-keymap nil
  "Local keymap used in simple-merge `fast' mode.
Makes simple-merge commands directly available.")

(defvar simple-merge-minor-mode nil)


(defun simple-merge-setup-keymaps ()
  (setq simple-merge-basic-keymap (make-sparse-keymap))
  (define-key simple-merge-basic-keymap "e" 'simple-merge-set-edit-keymap)
  (define-key simple-merge-basic-keymap "f" 'simple-merge-set-fast-keymap)
  (define-key simple-merge-basic-keymap "n" 'simple-merge-jump-next-conflict)
  (define-key simple-merge-basic-keymap "p" 'simple-merge-jump-prev-conflict)
  (define-key simple-merge-basic-keymap "b" 'simple-merge-keep-base-version)
  (define-key simple-merge-basic-keymap "t" 'simple-merge-keep-theirs-version)
  (define-key simple-merge-basic-keymap "y" 'simple-merge-keep-yours-version)
  (define-key simple-merge-basic-keymap "k" 'simple-merge-keep-current-version)
  (define-key simple-merge-basic-keymap "u" 'undo)
  (define-key simple-merge-basic-keymap "<" 'simple-merge-diff-base-yours)
  (define-key simple-merge-basic-keymap ">" 'simple-merge-diff-base-theirs)
  (define-key simple-merge-basic-keymap ":" 'simple-merge-diff-yours-theirs)
  (define-key simple-merge-basic-keymap "=" 'delete-other-windows)
  (define-key simple-merge-basic-keymap "l" 'simple-merge-mark-conflicts)
  (define-key simple-merge-basic-keymap "!" 'simple-merge-remove-trivial)
  (fset 'simple-merge-basic-keymap simple-merge-basic-keymap)

  (setq simple-merge-edit-keymap (if (current-local-map)
				     (copy-keymap (current-local-map))
				   (make-sparse-keymap)))
  (define-key simple-merge-edit-keymap
    simple-merge-command-prefix simple-merge-basic-keymap)

  (setq simple-merge-fast-keymap (copy-keymap simple-merge-basic-keymap))
  (define-key simple-merge-fast-keymap
    simple-merge-command-prefix 'simple-merge-basic-keymap))

(defun simple-merge-mode ()
  "Major mode to simplify editing output from the diff3 program.

simple-merge-mode makes it easier to edit files containing
\"conflict marks\", generated for example by diff3 and CVS.

There are two modes of operation, \"edit mode\" and \"fast mode\".
Fast mode is the default mode.

Special key bindings in \"fast mode\":
\\<simple-merge-fast-keymap>\

   \\[simple-merge-set-edit-keymap]\
   Switch to edit mode
   \\[simple-merge-set-fast-keymap]\
   Switch to fast mode
   \\[simple-merge-jump-next-conflict]\
   Jump to next conflict mark
   \\[simple-merge-jump-prev-conflict]\
   Jump to previous conflict mark
   \\[simple-merge-keep-base-version]\
   Keep 'base' version in current conflict region
   \\[simple-merge-keep-theirs-version]\
   Keep 'theirs' version in current conflict region
   \\[simple-merge-keep-yours-version]\
   Keep 'yours' version in current conflict region
   \\[simple-merge-keep-current-version]\
   Keep current version (the version at the current cursor location)
       in current conflict region
   \\[undo]\
   Undo previous command
   \\[simple-merge-diff-base-yours]\
   Diff 'base' and 'yours' version of current conflict region
   \\[simple-merge-diff-base-theirs]\
   Diff 'base' and 'theirs' version of current conflict region
   \\[simple-merge-diff-yours-theirs]\
   Diff 'yours' and 'theirs' version of current conflict region
   \\[delete-other-windows]\
   Delete other windows
   \\[simple-merge-mark-conflicts]\
   Mark conflict regions
   \\[simple-merge-remove-trivial]\
   Remove all trivial conflicts, ie where yours and theirs are equal

In `edit' mode, commands must be prefixed by \\[simple-merge-basic-keymap].\n"
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'simple-merge-mode)
  (setq mode-name "SimpleMerge")

  (simple-merge-setup-keymaps)

  (make-local-variable 'simple-merge-minor-mode)
  (or (assoc 'simple-merge-minor-mode minor-mode-alist)
      (setq minor-mode-alist
	    (cons '(simple-merge-minor-mode simple-merge-minor-mode)
		  minor-mode-alist)))

  (simple-merge-set-fast-keymap)
  (simple-merge-mark-conflicts)
  (run-hooks 'simple-merge-mode-hook))


(defun simple-merge-set-fast-keymap ()
  "Set simple-merge fast mode."
  (interactive)
  (use-local-map simple-merge-fast-keymap)
  (setq simple-merge-minor-mode " Fast")
  (force-mode-line-update))

(defun simple-merge-set-edit-keymap ()
  "Set simple-merge edit mode."
  (interactive)
  (use-local-map simple-merge-edit-keymap)
  (setq simple-merge-minor-mode " Edit")
  (force-mode-line-update))


(defun simple-merge-jump-next-conflict ()
  "Move cursor to the beginning of the next conflict region."
  (interactive)
  (let ((p nil))
    (save-excursion
      (forward-line 1)
      (if (not (re-search-forward "^<<<<<<<" nil t))
	  (error "No more conflicts"))
      (move-to-column 0)
      (setq p (point)))
    (goto-char p)))

(defun simple-merge-jump-prev-conflict ()
  "Move cursor to the beginning of the previous conflict region."
  (interactive)
  (if (not (re-search-backward "^<<<<<<<" nil t))
      (error "No previous conflict")))

(defun simple-merge-get-region-info-no-nil ()
  (let ((region-info (simple-merge-analyze-conflict-region)))
    (if (not region-info)
	(error "Point not in conflict region"))
    region-info))

(defun simple-merge-keep-base-version ()
  "Keep 'base' version in current conflict region."
  (interactive)
  (let ((region-info (simple-merge-get-region-info-no-nil))
	keep-string)
    (setq keep-string (buffer-substring
		       (cdr (assq 'base-start region-info))
		       (cdr (assq 'base-end region-info))))
    (delete-region (cdr (assq 'start region-info))
		   (cdr (assq 'end region-info)))
    (goto-char (cdr (assq 'start region-info)))
    (insert keep-string)))

(defun simple-merge-keep-theirs-version ()
  "Keep 'theirs' version in current conflict region."
  (interactive)
  (let ((region-info (simple-merge-get-region-info-no-nil))
	keep-string)
    (setq keep-string (buffer-substring
		       (cdr (assq 'theirs-start region-info))
		       (cdr (assq 'theirs-end region-info))))
    (delete-region (cdr (assq 'start region-info))
		   (cdr (assq 'end region-info)))
    (goto-char (cdr (assq 'start region-info)))
    (insert keep-string)))

(defun simple-merge-keep-yours-version ()
  "Keep 'yours' version in current conflict region."
  (interactive)
  (let ((region-info (simple-merge-get-region-info-no-nil))
	keep-string)
    (setq keep-string (buffer-substring
		       (cdr (assq 'yours-start region-info))
		       (cdr (assq 'yours-end region-info))))
    (delete-region (cdr (assq 'start region-info))
		   (cdr (assq 'end region-info)))
    (goto-char (cdr (assq 'start region-info)))
    (insert keep-string)))

(defun simple-merge-keep-current-version ()
  "Keep 'current' (under the cursor) version in current conflict region."
  (interactive)
  (let ((region-info (simple-merge-get-region-info-no-nil))
	type)
    (setq type (cdr (assq 'active-block region-info)))
    (cond ((eq type 'yours)
	   (simple-merge-keep-yours-version))
	  ((eq type 'base)
	   (simple-merge-keep-base-version))
	  ((eq type 'theirs)
	   (simple-merge-keep-theirs-version))
	  (t
	   (error "Invalid cursor location")))))

(defun simple-merge-diff-base-yours ()
  "Diff 'base' and 'yours' version in current conflict region."
  (interactive)
  (let ((region-info (simple-merge-get-region-info-no-nil))
	string1 string2)
    (setq string1 (buffer-substring
		   (cdr (assq 'base-start region-info))
		   (cdr (assq 'base-end region-info))))
    (setq string2 (buffer-substring
		   (cdr (assq 'yours-start region-info))
		   (cdr (assq 'yours-end region-info))))
    (simple-merge-create-diff string1 string2 "base" "yours")))

(defun simple-merge-diff-base-theirs ()
  "Diff 'base' and 'theirs' version in current conflict region."
  (interactive)
  (let ((region-info (simple-merge-get-region-info-no-nil))
	string1 string2)
    (setq string1 (buffer-substring
		   (cdr (assq 'base-start region-info))
		   (cdr (assq 'base-end region-info))))
    (setq string2 (buffer-substring
		   (cdr (assq 'theirs-start region-info))
		   (cdr (assq 'theirs-end region-info))))
    (simple-merge-create-diff string1 string2 "base" "theirs")))

(defun simple-merge-diff-yours-theirs ()
  "Diff 'yours' and 'theirs' version in current conflict region."
  (interactive)
  (let ((region-info (simple-merge-get-region-info-no-nil))
	string1 string2)
    (setq string1 (buffer-substring
		   (cdr (assq 'yours-start region-info))
		   (cdr (assq 'yours-end region-info))))
    (setq string2 (buffer-substring
		   (cdr (assq 'theirs-start region-info))
		   (cdr (assq 'theirs-end region-info))))
    (simple-merge-create-diff string1 string2 "yours" "theirs")))


(defun simple-merge-in-region-p (p a b)
  (and (>= p a)
       (< p b)))

(defun simple-merge-analyze-conflict-region ()
  (save-excursion
    (let ((region-info nil)
	  (orig-point (point)))
      (forward-line 1)
      (if (not (re-search-backward "^<<<<<<<" nil t))
	  nil
	(let (start end yours-start yours-end base-start base-end
		    theirs-start theirs-end active-block)
	  (setq start (point))
	  (if (not (re-search-forward "^>>>>>>>" nil t))
	      nil
	    (move-to-column 0)
	    (setq yours-start (point))
	    (setq yours-end (point))
	    (setq base-start (point))
	    (setq base-end (point))
	    (setq theirs-start (point))
	    (setq theirs-end (point))

	    (forward-line 1)
	    (setq end (point))

	    (goto-char start)
	    (forward-line 1)
	    (setq yours-start (point))

	    (if (re-search-forward "^=======" end t)
		(progn
		  (move-to-column 0)
		  (setq yours-end (point))
		  (setq base-end (point))
		  (forward-line 1)
		  (setq theirs-start (point))))

	    (goto-char start)
	    (if (re-search-forward "^|||||||" end t)
		(progn
		  (move-to-column 0)
		  (setq yours-end (point))
		  (forward-line 1)
		  (setq base-start (point))))

	    (setq active-block
		  (cond ((simple-merge-in-region-p orig-point yours-start yours-end)
			 'yours)
			((simple-merge-in-region-p orig-point base-start base-end)
			 'base)
			((simple-merge-in-region-p orig-point theirs-start theirs-end)
			 'theirs)
			(t nil)))

	    (setq yours-start (min yours-start yours-end))
	    (setq base-start (min base-start base-end))
	    (setq theirs-start (min theirs-start theirs-end))

	    (if (simple-merge-in-region-p orig-point start end)
		(setq region-info (list (cons 'start start)
					(cons 'end end)
					(cons 'yours-start yours-start)
					(cons 'yours-end yours-end)
					(cons 'base-start base-start)
					(cons 'base-end base-end)
					(cons 'theirs-start theirs-start)
					(cons 'theirs-end theirs-end)
					(cons 'active-block active-block)))))))
      region-info)))

(defun simple-merge-mark-conflicts ()
  "Mark conflict regions with different foreground colors."
  (interactive)
  (make-face 'simple-merge-yours-face)
  (set-face-foreground 'simple-merge-yours-face "blue")
  (make-face 'simple-merge-theirs-face)
  (set-face-foreground 'simple-merge-theirs-face "darkgreen")
  (make-face 'simple-merge-base-face)
  (set-face-foreground 'simple-merge-base-face "red")
  (let ((modified (buffer-modified-p))
	(conflicts 0))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^<<<<<<<" nil t)
	(setq conflicts (1+ conflicts))
	(let ((region-info (simple-merge-analyze-conflict-region)))
	  (put-text-property (cdr (assq 'yours-start region-info))
			     (cdr (assq 'yours-end region-info))
			     'face 'simple-merge-yours-face)

	  (put-text-property (cdr (assq 'base-start region-info))
			     (cdr (assq 'base-end region-info))
			     'face 'simple-merge-base-face)

	  (put-text-property (cdr (assq 'theirs-start region-info))
			     (cdr (assq 'theirs-end region-info))
			     'face 'simple-merge-theirs-face))))
    (set-buffer-modified-p modified)
    (message "%d conflicts found" conflicts)))

;; Function to show the current version.
(defun simple-merge-version ()
  "Show the current simple-merge version."
  (interactive)
  (message "Simple merge version %s" simple-merge-version))

(defun simple-merge-create-diff (string1 string2 name1 name2)
  (let ((buf-name "simple-merge-diff")
	(file1 (make-temp-name "/tmp/smerge1"))
	(file2 (make-temp-name "/tmp/smerge2")))
    (write-region string1 0 file1)
    (write-region string2 0 file2)
    (get-buffer-create buf-name)
    (kill-buffer buf-name)
    (apply 'call-process "diff" nil (get-buffer-create buf-name) nil
	   (list "-du" "-L" name1 "-L" name2 file1 file2))
    (delete-file file1)
    (delete-file file2)
    (display-buffer buf-name t)
    (save-excursion
      (set-buffer buf-name)
      (setq buffer-read-only t))
    (save-selected-window
      (select-window (get-buffer-window buf-name))
      (goto-char (point-min)))))

(defun simple-merge-remove-trivial ()
  "Remove all conflicts where yours and theirs are identical."
  (interactive)
  (if (not (yes-or-no-p "Remove all trivial conflicts? "))
      (error "Aborted!"))
  (goto-char (point-min))
  (condition-case
   nil
   (while t
     (simple-merge-jump-next-conflict)
     (if (looking-at "<<<<<<< base")
	 (simple-merge-keep-theirs-version)))
   (error (message "All trivial conflicts removed")))
  (goto-char (point-min)))
