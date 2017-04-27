;;; package --- Summary

;;; Commentary:

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LOAD FILES
(load-file "~/.emacs.d/private/tddsg/local/golden-ratio/golden-ratio.el")


(require 'smartparens)
(require 'company)
(require 'powerline)
(require 'buffer-move)
(require 'pdf-sync)
(require 'spaceline-segments)
(require 'spaceline)
(require 'pdf-view)
(require 'pdf-tools)
(require 'face-remap)
(require 'magit-gitflow)
(require 'whitespace)
(require 'god-mode)
(require 'god-mode-isearch)
(require 'expand-region)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PRIVATE FUNCTIONS

(defun tddsg--blank-line-p ()
  (save-excursion
    (beginning-of-line)
    (looking-at "[ \t]*$")))

(defun tddsg--blank-char-p (ch)
  (or (equal (string ch) " ") (equal (string ch) "\\t")))

(defun tddsg--set-mark ()
  (push-mark (point) t nil))

(defun tddsg--projectile-p ()
  "Check if a projectile exists in the current buffer."
  (and projectile-mode
       (not (string= (projectile-project-name) ""))
       (not (string= (projectile-project-name) "-"))))

(defun tddsg--fix-comint-window-size ()
  "Change process window size."
  (when (derived-mode-p 'comint-mode)
    (let ((process (get-buffer-process (current-buffer))))
      (when process
        (set-process-window-size process (window-height) (window-width))))))

(defun tddsg--create-backup-file-name (fpath)
  "Return a new file path of a given file path.
If the new path's directories does not exist, create them."
  (let* ((backup-root "~/.emacs.d/private/backup/")
         ;; remove Windows driver letter in path, for example: “C:”
         (file-path (replace-regexp-in-string "[A-Za-z]:" "" fpath ))
         (backup-filepath (replace-regexp-in-string
                          "//" "/" (concat backup-root file-path "~"))))
    (make-directory (file-name-directory backup-filepath)
                    (file-name-directory backup-filepath))
    backup-filepath))

(defun tddsg--save-buffer ()
  "Save current buffer."
  (if (and (not buffer-read-only)
           (derived-mode-p 'text-mode 'prog-mode))
      (save-buffer)))

(defun tddsg--latex-compile ()
  (interactive)
  (save-buffer)
  ;; (setq TeX-after-compilation-finished-functions nil)
  ;; (call-interactively 'latex/compile-commands-until-done)
  (TeX-command "LaTeX" 'TeX-master-file -1))

(defun tddsg--latex-compile-sync-forward ()
  (interactive)
  (call-interactively 'latex/compile-commands-until-done)
  (call-interactively 'pdf-sync-forward-search))

(defun tddsg--highlight-todos ()
  (font-lock-add-keywords nil '(("\\b\\(TODO\\|FIXME\\|BUG\\)\\b"
                                 1 (hl-todo-get-face) t)))
  (font-lock-add-keywords nil '(("\\b\\(NOTE\\|DONE\\|IMPORTANT\\)\\b"
                                 1 (hl-todo-get-face) t))))

(defun tddsg--is-small-screen ()
  (string= (system-name) "pisces"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HOOK FUNCTIONS

(defun tddsg--hook-change-major-mode ()
  ;; change some weird keys
  (keyboard-translate ?\C-\[ ?\H-\[)
  (keyboard-translate ?\C-i ?\H-i)
  (keyboard-translate ?\C-m ?\H-m)
  (define-key input-decode-map (kbd "C-M-[") (kbd "H-M-["))
  (define-key input-decode-map (kbd "C-S-I") (kbd "H-I"))
  (define-key input-decode-map (kbd "C-S-M") (kbd "H-M"))
  ;; change personal dictionary of ispell
  (if (tddsg--projectile-p)
      (setq ispell-personal-dictionary (concat (projectile-project-root)
                                               "user.dict"))))

(defun tddsg--hook-prog-text-mode ()
  ;; linum-mode
  (when (derived-mode-p 'songbird 'c-mode 'cc-mode 'python-mode)
    (linum-mode 1))
  (tddsg--highlight-todos)
  (smartparens-mode 1)
  (column-marker-3 76)
  (whitespace-mode 1))

(defun tddsg--hook-prog-mode ()
  (flycheck-mode 1))

(defun tddsg--hook-text-mode ()
  (flyspell-mode 1))

(defun tddsg--hook-shell-mode ()
  (add-hook 'window-configuration-change-hook
            'tddsg--fix-comint-window-size nil t)
  (rainbow-delimiters-mode-disable)
  (toggle-truncate-lines -1)
  (visual-line-mode 1))

(defun tddsg--hook-term-mode ()
  (term-set-escape-char ?\C-x))

(defun tddsg--rectify-golden-ratio ()
  (with-current-buffer (window-buffer (selected-window))
    (if (and golden-ratio-mode
             (not (derived-mode-p 'pdf-view-mode)))
        (golden-ratio 1))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INTERACTIVE FUNCTIONS

(defun tddsg/show-and-copy-path-current-buffer ()
  "Show path of the current buffer."
  (interactive)
  (kill-new (buffer-file-name))
  (message "Current path: %s" (buffer-file-name)))

(defun tddsg/previous-overlay ()
  "Go to previous overlay."
  (interactive)
  (let ((posn (-  (previous-overlay-change (point)) 1)))
    (if (not (null (overlays-at posn)))
        (goto-char posn)))
  ;; (goto-char (previous-overlay-change (point)))
  ;; (while (and (not (bobp))
  ;;             (not (memq (char-syntax (char-after)) '(?w))))
  ;;   (goto-char (previous-overlay-change (point))))
  )

(defun tddsg/shell-current-window (&optional buffer)
  "Open a `shell' in the current window."
  (interactive)
  (let ((window (selected-window))
        (window-config (current-window-configuration))
        (shell-buffer (call-interactively 'shell)))
    (set-window-configuration window-config)
    (select-window window)
    (switch-to-buffer shell-buffer)))

(defun tddsg/shell-other-window (&optional buffer)
  "Open a `shell' in a new window."
  (interactive)
  (when (equal (length (window-list)) 1)
    (call-interactively 'split-window-right))
  (call-interactively 'other-window)
  (call-interactively 'tddsg/shell-current-window))

(defun tddsg/term-current-window (arg)
  "Open a `term' in the current window."
  (interactive "P")
  (defun last-term-buffer (buffers)
    (when buffers
      (if (eq 'term-mode (with-current-buffer (car buffers) major-mode))
          (car buffers)
        (last-term-buffer (cdr buffers)))))
  (let* ((window (selected-window))
         (window-config (current-window-configuration))
         (last-term (last-term-buffer (buffer-list)))
         (term-buffer (if (or (not (null arg))
                              (null last-term)
                              (eq 'term-mode major-mode))
                          (multi-term)
                        (switch-to-buffer last-term))))
    (set-window-configuration window-config)
    (select-window window)
    (switch-to-buffer term-buffer)))

(defun tddsg/term-other-window (arg)
  "Open a `term' in a new window."
  (interactive "P")
  (when (equal (length (window-list)) 1)
    (call-interactively 'split-window-right))
  (call-interactively 'other-window)
  (call-interactively 'tddsg/term-current-window))

(defun tddsg/save-file-as-and-open-file (filename &optional confirm)
  "Save current buffer into file FILENAME and open it in a new buffer."
  (interactive
   (list (if buffer-file-name
             (read-file-name "Save as and open file: "
                             nil nil nil nil)
           (read-file-name "Save as and open file: " default-directory
                           (expand-file-name
                            (file-name-nondirectory (buffer-name))
                            default-directory)
                           nil nil))
         (not current-prefix-arg)))
  (or (null filename) (string-equal filename "")
      (progn
        ;; If arg is just a directory,
        ;; use the default file name, but in that directory.
        (if (file-directory-p filename)
            (setq filename (concat (file-name-as-directory filename)
                                   (file-name-nondirectory
                                    (or buffer-file-name (buffer-name))))))
        (and confirm
             (file-exists-p filename)
             ;; NS does its own confirm dialog.
             (not (and (eq (framep-on-display) 'ns)
                       (listp last-nonmenu-event)
                       use-dialog-box))
             (or (y-or-n-p (format "File `%s' exists; overwrite? " filename))
                 (error "Canceled")))
        (write-region (point-min) (point-max) filename )
        (find-file filename)))
  (vc-find-file-hook))

(defun tddsg/dired-home ()
  (interactive)
  (dired "~/"))

(defun tddsg/dired-duplicate-files ()
  "Duplicate files to the current folder by adding suffix \" - COPY\"."
  (interactive)
  ;; TODO: how to deal with file names having no \".\". For example: TODO files
  (dired-do-copy-regexp "\\(.*\\)\\.\\(.*\\)" "\\1 - (COPY).\\2"))

(defun tddsg/duplicate-region-or-line ()
  "Duplicate a selected region or a line."
  (interactive)
  (if (not (region-active-p)) (tddsg/mark-line))
  (call-interactively 'kill-ring-save)
  (newline-and-indent)
  (yank)
  (indent-region))

(defun tddsg/mark-line ()
  "Select current line"
  (interactive)
  (end-of-line)
  (set-mark (line-beginning-position)))

(defun tddsg/mark-sexp (&optional backward)
  "Mark sexp using the smartparens package."
  (let ((step (if (null backward) 1 -1)))
    (if (region-active-p)
        (sp-forward-sexp step)
      (cond ((and (null backward)
                  (not (null (char-before)))
                  (memq (char-syntax (char-before)) '(?w ?_)))
             (backward-sexp))
            ((and (not (null backward))
                  (not (null (char-after)))
                  (memq (char-syntax (char-after)) '(?w ?_)))
             (forward-sexp)))
      (set-mark-command nil)
      (sp-forward-sexp step))))

(defun tddsg/mark-sexp-forward ()
  "Mark sexp forward, using the smartparens package."
  (interactive)
  (tddsg/mark-sexp))

(defun tddsg/mark-sexp-backward ()
  "Mark sexp backward, using the smartparens package."
  (interactive)
  (tddsg/mark-sexp t))

(defun tddsg/mark-paragraph ()
  "Mark the paragraph."
  (interactive)
  (if (region-active-p) (forward-paragraph 1)
    (progn
      (beginning-of-line)
      (beginning-of-line)
      (backward-paragraph 1)
      (next-line)
      (backward-paragraph 1)
      (beginning-of-line)
      (beginning-of-line)
      (if (looking-at "[[:space:]]*$") (next-line 1))
      (beginning-of-line)
      (beginning-of-line)
      (set-mark-command nil)
      (forward-paragraph 1))))

(defun tddsg/comment-paragraph ()
  "Comment the paragraph."
  (interactive)
  (tddsg/mark-paragraph)
  (call-interactively 'comment-dwim-2))

(defun tddsg/smart-kill-sexp (&optional backward)
  "Kill sexp smartly."
  (interactive)
  (defun space-or-tab-p (char)
    (or (equal char ?\s) (equal char ?\t)))
  (defun kill-region-and-next-spaces (begin end &optional backward)
    (if backward
        (cl-loop
         while (and (space-or-tab-p (char-before begin))
                    (or (null (char-before (1+ begin)))
                        (null (char-after end))
                        (not (memq (char-syntax (char-before (1+ begin))) '(?w ?_)))
                        (not (memq (char-syntax (char-after end)) '(?w ?_)))))
         do (setq begin (1- begin)))
      (cl-loop
       while (and (space-or-tab-p (char-after end))
                  (or (null (char-before begin))
                      (null (char-after (1+ end)))
                      (not (memq (char-syntax (char-before begin)) '(?w ?_)))
                      (not (memq (char-syntax (char-after (1+ end))) '(?w ?_)))))
       do (setq end (1+ end))))
    (kill-region begin end)
    (when (and (not (null (char-before)))
               (memq (char-syntax (char-after)) '(?w ?_))
               (memq (char-syntax (char-before)) '(?w ?_ ?.)))
      (just-one-space)))
  (if (region-active-p) (delete-active-region t)
    (cond ((and backward
                (not (space-or-tab-p (char-after)))
                (not (null (char-before)))
                (space-or-tab-p (char-before)))
           (forward-char -1))
          ((and (not backward)
                (space-or-tab-p (char-after))
                (not (null (char-before)))
                (not (space-or-tab-p (char-before))))
           (forward-char 1)))
    (setq begin (if backward (1- (point)) (point)))
    (setq end (if backward (point) (1+ (point))))
    (setq thing (sp-get-thing backward))
    (when (and (not (null thing))
               (>= (point) (cadr thing))
               (<= (point) (cadddr thing)))
      (setq begin (cadr thing))
      (setq end (cadddr thing)))
    (kill-region-and-next-spaces begin end backward)
    (when (and (not (null (char-before)))
               (memq (char-syntax (char-after)) '(?w ?_))
               (memq (char-syntax (char-before)) '(?w ?_)))
      (just-one-space))))

(defun tddsg/smart-kill-sexp-forward ()
  "Kill sexp forward."
  (interactive)
  (tddsg/smart-kill-sexp))

(defun tddsg/smart-kill-sexp-backward ()
  "Kill sexp backward."
  (interactive)
  (tddsg/smart-kill-sexp t))

(defun tddsg/helm-do-ag (arg)
  "Search by Helm-Ag in the current directory, \
or in a custom directory when prefix-argument is given <C-u>."
  (interactive "P")
  (if (null arg)
      (let* ((text (if (region-active-p)
                       (buffer-substring (region-beginning) (region-end))
                     (thing-at-point 'word)))
             (text (if (null text) "" text))
             (text (replace-regexp-in-string " " "\\\\ " (string-trim text))))
        (helm-do-ag (expand-file-name default-directory) text))
    (call-interactively 'helm-do-ag)))

(defun tddsg/join-with-beneath-line ()
  "Join the current line to the line beneath it."
  (interactive)
  (delete-indentation 1)
  (let ((current-char (char-after)))
    (if (memq (char-syntax current-char) '(?w ?_ ?\" ?\( ?< ?>))
        (just-one-space))))

(defun tddsg/join-to-above-line ()
  "Join the current line to the line above it."
  (interactive)
  (delete-indentation)
  (delete-horizontal-space)
  (let ((current-char (char-after)))
    (if (memq (char-syntax current-char) '(?w ?_ ?\" ?\( ?< ?>))
        (just-one-space))))

(defun tddsg/one-space ()
  "Just one space in a region or in the current location."
  (interactive)
  (if (region-active-p)
      (save-excursion
        (save-restriction
          (narrow-to-region (region-beginning) (region-end))
          (goto-char (point-min))
          (while (re-search-forward "\\s-+" nil t)
            (replace-match " "))))
    (just-one-space)))

(defun tddsg/one-or-zero-space ()
  "Delete the space if there is only 1 space,
replace all spaces by 1 if there is more than 1,
insert a new space if there is none"
  (interactive)
  (if (region-active-p)
      (save-excursion
        (save-restriction
          (narrow-to-region (region-beginning) (region-end))
          (goto-char (point-min))
          (while (re-search-forward "\\s-+" nil t)
            (replace-match " "))))
    (if (tddsg--blank-char-p (preceding-char)) (forward-char -1))
    (if (tddsg--blank-char-p (following-char))
        (if (or (tddsg--blank-char-p (preceding-char))
                (tddsg--blank-char-p (char-after (+ (point) 1))))
            (just-one-space)
          (delete-char 1))
      (just-one-space))))

(defun tddsg/one-space-or-blank-line ()
  "Just one space or one line in a region or in the current location."
  (interactive)
  (if (region-active-p)
      (save-excursion
        (save-restriction
          (narrow-to-region (region-beginning) (region-end))
          (goto-char (point-min))
          (while (re-search-forward "\\s-+" nil t)
            (replace-match " "))))
    (if (tddsg--blank-line-p)
        (delete-blank-lines)
      (tddsg/one-or-zero-space))))

(defun tddsg/enlarge-window-horizontally ()
  "Enlarge window horizontally, considering golden-ratio-mode."
  (interactive)
  (if golden-ratio-mode
      (setq golden-ratio-adjust-factor (+ golden-ratio-adjust-factor 0.02)))
  (call-interactively 'enlarge-window-horizontally))

(defun tddsg/shrink-window-horizontally ()
  "Shrink window horizontally, considering golden-ratio-mode."
  (interactive)
  (if golden-ratio-mode
      (setq golden-ratio-adjust-factor (- golden-ratio-adjust-factor 0.02)))
  (call-interactively 'shrink-window-horizontally))

(defun tddsg/enlarge-window-vertically ()
  "Enlarge window vertically, considering golden-ratio-mode."
  (interactive)
  (if golden-ratio-mode
      (setq golden-ratio-adjust-factor-height
            (+ golden-ratio-adjust-factor-height 0.02)))
  (call-interactively 'enlarge-window))

(defun tddsg/shrink-window-vertically ()
  "Shrink window vertically, considering golden-ratio-mode."
  (interactive)
  (if golden-ratio-mode
      (setq golden-ratio-adjust-factor-height
            (- golden-ratio-adjust-factor-height 0.02)))
  (call-interactively 'shrink-window))


(defun tddsg/kill-ring-save (arg)
  "Save the current region (or line) to the `kill-ring'
after stripping extra whitespace and new lines"
  (interactive "P")
  (if (null arg)
      (call-interactively 'kill-ring-save)
    (if (region-active-p)
        (let* ((begin (region-beginning))
               (end (region-end))
               (text (buffer-substring-no-properties begin end))
               (text (replace-regexp-in-string "\n" " " text))
               (text (replace-regexp-in-string "\\s-+" " " text))
               (text (string-trim text)))
          (kill-new text)
          (deactivate-mark))
      (call-interactively 'kill-ring-save))))

(defun tddsg/pdf-view-kill-ring-save (arg)
  "Save the current region (or line) to the `kill-ring'
after stripping extra whitespace and new lines"
  (interactive "P")
  (if (null arg)
      (call-interactively 'pdf-view-kill-ring-save)
    (pdf-view-assert-active-region)
    (let* ((text (pdf-view-active-region-text))
           (text (mapconcat 'identity text " "))
           (text (replace-regexp-in-string "\n" " " text))
           (text (replace-regexp-in-string "\\s-+" " " text))
           (text (string-trim text)))
      (pdf-view-deactivate-region)
      (kill-new text))))

(defun tddsg/yank-current-word-to-minibuffer ()
  "Get word at point in original buffer and insert it to minibuffer."
  (interactive)
  (let (word beg)
    (with-current-buffer (window-buffer (minibuffer-selected-window))
      (save-excursion
        (skip-syntax-backward "w_")
        (setq beg (point))
        (skip-syntax-forward "w_")
        (setq word (buffer-substring-no-properties beg (point)))))
    (when word
      (insert word))))

(defun tddsg/yank-current-word-to-isearch-buffer ()
  "Pull current word from buffer into search string."
  (interactive)
  (save-excursion
    (skip-syntax-backward "w_")
    (isearch-yank-internal
     (lambda ()
       (skip-syntax-forward "w_")
       (point)))))

;; call compile to the closest parent folder containing a Makefile
(defun tddsg/compile ()
  (interactive)
  (cl-labels
      ((find-make-file-dir
        (cur-dir root-dir make-file)
        (cond ((string= cur-dir root-dir) "")
              ((file-exists-p (expand-file-name make-file cur-dir)) cur-dir)
              (t (find-make-file-dir (expand-file-name ".." cur-dir)
                                     root-dir
                                     make-file)))))
    (let* ((cur-dir default-directory)
           (root-dir "/")
           (make-file "Makefile")
           (new-command
            (if (and (>  (length compile-command) 4)
                     (string= (substring compile-command 0 4) "make"))
                (format "make -k -C %s"
                        (find-make-file-dir cur-dir root-dir make-file))
              compile-command)))
      (setq compile-command new-command)
      (call-interactively 'compile))))

(defun tddsg/unpop-to-mark-command ()
  "Unpop off mark ring. Does nothing if mark ring is empty."
  (interactive)
  (when mark-ring
    (setq mark-ring (cons (copy-marker (mark-marker)) mark-ring))
    (set-marker (mark-marker) (car (last mark-ring)) (current-buffer))
    (when (null (mark t)) (ding))
    (setq mark-ring (nbutlast mark-ring))
    (goto-char (marker-position (car (last mark-ring))))))

(defun tddsg/enable-company-auto-suggest ()
  (interactive)
  (setq company-idle-delay 0.5))

(defun tddsg/disable-company-auto-suggest ()
  (interactive)
  (setq company-idle-delay 300))

(defun tddsg/toggle-show-mode-line ()
  (interactive)
  (if (bound-and-true-p mode-line-format)
      (setq mode-line-format nil)
    (setq mode-line-format (default-value 'mode-line-format))))

(defun tddsg/toggle-shell-scroll-to-bottomon-on-output ()
  "Toggle shell scroll to the last line on output."
  (interactive)
  (if (derived-mode-p 'shell-mode)
      (cond (comint-scroll-to-bottom-on-output
             (setq comint-scroll-to-bottom-on-output nil)
             (setq mode-name "Shell ⚡⚡⚡"))
            (t
             (setq comint-scroll-to-bottom-on-output t)
             (setq mode-name "Shell")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INIT CONFIGS

(defun tddsg/init-configs ()
  ;; specific setting for each machines
  (if (tddsg--is-small-screen)
      (progn
        (global-linum-mode -1)
        (setq golden-ratio-adjust-factor 1.05)
        (setq golden-ratio-balance nil)
        (golden-ratio-mode))
    (setq golden-ratio-adjust-factor 1.618)
    (setq golden-ratio-balance nil))

  ;; visual interface setting
  (display-time)                    ;; show time in mode line
  (global-hl-todo-mode 1)           ;; highlight todo mode
  (blink-cursor-mode 0)             ;; turn off blinking
  (setq blink-cursor-blinks 15)     ;; blink 15 times
  (setq fill-column 75)             ;; max size of a line for fill-or-unfill
  (setq fast-but-imprecise-scrolling nil)
  (setq text-scale-mode-step 1.1)   ;; scale changing font size
  (setq frame-title-format          ;; frame title
        '("" invocation-name " - "
          (:eval (if (buffer-file-name)
                     (abbreviate-file-name (buffer-file-name)) "%b"))))

  ;; windows setting
  (setq window-combination-resize nil)   ;; stop Emacs from automatically resize windows

  ;; scrolling
  (spacemacs/toggle-smooth-scrolling-off)  ;; disable smooth-scrolling
  (setq redisplay-dont-pause t
        scroll-conservatively 101
        scroll-margin 0                    ;; perfect setting for scrolling
        next-screen-context-lines 0        ;; perfect setting for scrolling
        scroll-preserve-screen-position 't)

  ;; mode paragraph setting
  (setq paragraph-separate "[ \t\f]*$"
        paragraph-start "\f\\|[ \t]*$")

  ;; save
  ;; (add-hook 'before-save-hook 'delete-trailing-whitespace)
  (add-to-list 'write-file-functions 'delete-trailing-whitespace)

  ;; zoom frame
  (require 'zoom-frm)

  ;; auto-completetion
  (setq dabbrev-case-replace nil)

  ;; visual line mode
  (setq visual-line-fringe-indicators '(left-curly-arrow right-curly-arrow))

  ;; spell
  (setq ispell-program-name "aspell" ; use aspell instead of ispell
        ispell-extra-args '("--sug-mode=ultra")
        ispell-dictionary "english"
        ispell-personal-dictionary "~/.emacs.d/user.dict")

  ;; mark ring
  (setq set-mark-command-repeat-pop t)
  (defadvice find-file (before set-mark activate) (tddsg--set-mark))
  (defadvice isearch-update (before set-mark activate) (tddsg--set-mark))
  (defadvice beginning-of-buffer (before set-mark activate) (tddsg--set-mark))
  (defadvice end-of-buffer (before set-mark activate) (tddsg--set-mark))
  (defadvice merlin-locate (before set-mark activate) (tddsg--set-mark))

  ;; company-mode
  (setq company-idle-delay 300)
  (setq company-tooltip-idle-delay 300)
  (global-company-mode)

  ;; pdf-view
  (defun update-pdf-view-theme ()
    (when (derived-mode-p 'pdf-view-mode)
      (cond ((eq spacemacs--cur-theme 'spacemacs-dark)
             (if (not (bound-and-true-p pdf-view-midnight-minor-mode))
                 (pdf-view-midnight-minor-mode)))
            ((eq spacemacs--cur-theme 'leuven)
             (if (bound-and-true-p pdf-view-midnight-minor-mode)
                 (pdf-view-midnight-minor-mode -1))))))
  (defadvice spacemacs/cycle-spacemacs-theme (after pdf-view activate)
    (mapc (lambda (window)
            (with-current-buffer (window-buffer window)
              (update-pdf-view-theme)))
          (window-list)))
  (add-hook 'pdf-view-mode-hook 'update-pdf-view-theme)

  ;; mode editing setting
  (electric-pair-mode t)
  (delete-selection-mode t)                            ;; delete selection by keypress
  (setq require-final-newline t)                       ;; newline at end of file
  (defadvice newline (after indent activate) (indent-according-to-mode))

  ;; some Emacs threshold
  (setq max-lisp-eval-depth 50000)
  (setq max-specpdl-size 50000)

  ;; mode-line setting
  (setq powerline-default-separator 'wave)

  ;; golden-ratio
  (add-hook 'buffer-list-update-hook 'tddsg--rectify-golden-ratio)

  ;; themes
  (defun tddsg--update-cursor ()
    (cond ((or (bound-and-true-p god-mode)
               (bound-and-true-p god-global-mode))
           (set-cursor-color "lime green"))
          ((eq spacemacs--cur-theme 'leuven)
           (set-cursor-color "dark orange"))
          ((eq spacemacs--cur-theme 'spacemacs-dark)
           (set-cursor-color "dark orange"))))
  (add-hook 'buffer-list-update-hook 'tddsg--update-cursor)

  ;; isearch
  (defun tddsg--isearch-show-case-fold (orig-func &rest args)
    (apply orig-func args)
    (if isearch-case-fold-search
        (spacemacs|diminish isearch-mode "⚡ISearch[ci]⚡")
      (spacemacs|diminish isearch-mode "⚡ISearch[CS]⚡")))
  (advice-add 'isearch-mode :around #'tddsg--isearch-show-case-fold)
  (advice-add 'isearch-repeat :around #'tddsg--isearch-show-case-fold)
  (advice-add 'isearch-toggle-case-fold :around #'tddsg--isearch-show-case-fold)
  ;; (add-hook 'isearch-update-post-hook 'update-pdf-view-theme)


  ;; compilation
  (setq compilation-ask-about-save nil
        compilation-window-height 15)

  ;; shell
  (setq comint-prompt-read-only nil)
  (setq shell-default-shell 'ansi-term)
  (add-hook 'shell-mode-hook 'tddsg--hook-shell-mode)

  ;; term mode
  (require 'multi-term)
  (multi-term-keystroke-setup)
  (setq multi-term-program "/bin/bash"
        multi-term-program-switches "--login")
  (setq term-bind-key-alist
        (list (cons "C-c C-j" 'term-line-mode)
              (cons "C-c C-c" 'term-send-raw)
              (cons "M-n" 'term-send-down)
              (cons "M-p" 'term-send-up)
              (cons "C-<down>" 'term-send-down)
              (cons "C-<up>" 'term-send-up)))
  (define-key term-raw-map (kbd "C-u") nil)
  (add-hook 'term-mode-hook 'tddsg--hook-term-mode)

  ;; ediff-mode
  (add-hook 'ediff-mode-hook '(lambda () (golden-ratio-mode -1)))

  ;; automatically save buffer
  (defadvice magit-status (before save-buffer activate) (tddsg--save-buffer))
  (defadvice winum-select-window-by-number
      (before save-buffer activate) (tddsg--save-buffer))

  ;; tramp
  (require 'tramp)
  (add-to-list 'tramp-default-proxies-alist '(nil "\\`root\\'" "/ssh:%h:"))
  (add-to-list 'tramp-default-proxies-alist
               '((regexp-quote (system-name)) nil nil))

  ;; which-key
  (setq which-key-idle-delay 1.2)

  ;; smartparens
  (smartparens-global-mode)

  ;; auto-revert
  (setq auto-revert-check-vc-info nil)

  ;; backup
  (setq make-backup-files t
        make-backup-file-name-function 'tddsg--create-backup-file-name)

  ;; evil mode
  (evil-mode -1)
  (setq-default evil-cross-lines t)

  ;; dired
  (add-to-list 'savehist-additional-variables 'helm-dired-history-variable)
  (setq dired-guess-shell-alist-user
        '(("\\.pdf\\'" "okular &")
          ("\\.html\\'" "google-chrome &")
          ("\\.txt\\'" "gedit")))

  ;; helm setting
  (setq helm-ag-insert-at-point 'symbol)     ;; insert symbol in helm-ag
  (setq helm-split-window-in-side-p t)
  (setq helm-split-window-default-side 'below)

  ;; reason-mode
  (tddsg/init-reason-mode)

  ;; diminish
  (spacemacs|diminish whitespace-mode "")
  (spacemacs|diminish super-save-mode "")
  (spacemacs|diminish company-mode "")
  (spacemacs|diminish which-key-mode "")
  (spacemacs|diminish yas-minor-mode "")
  (spacemacs|diminish latex-extra-mode "")
  (spacemacs|diminish utop-minor-mode "")
  (spacemacs|diminish golden-ratio-mode "")
  (spacemacs|diminish with-editor-mode "")
  (spacemacs|diminish compilation-in-progress "")
  (spacemacs|diminish server-buffer-clients "")
  (spacemacs|diminish reftex-mode "")
  (spacemacs|diminish pdf-view-midnight-minor-mode "")
  (spacemacs|diminish auto-revert-mode " ↺")
  (spacemacs|diminish god-local-mode " ⚡☢⚡☢⚡")
  (spacemacs|diminish abbrev-mode " ↹")
  (spacemacs|diminish smartparens-mode " ♓")
  (spacemacs|diminish rainbow-mode " ☔")
  (spacemacs|diminish auto-fill-function " ↪")
  (spacemacs|diminish visual-line-mode " ↩")
  (spacemacs|diminish merlin-mode " ♏")
  (spacemacs|diminish magit-gitflow-mode " ♒")
  (spacemacs|diminish flycheck-mode " ⚐")
  (spacemacs|diminish flyspell-mode " ✔")
  (spacemacs|diminish holy-mode " ☼")
  (spacemacs|diminish projectile-mode " ♖")
  (spacemacs|diminish compilation-minor-mode "⚡⚡⚡COMPILING⚡⚡⚡")

  ;; hooks, finally hook
  (add-hook 'LaTeX-mode-hook 'tddsg--hook-prog-text-mode)
  (add-hook 'TeX-mode-hook 'tddsg--hook-prog-text-mode)
  (add-hook 'tex-mode-hook 'tddsg--hook-prog-text-mode)
  (add-hook 'prog-mode-hook 'tddsg--hook-prog-text-mode)
  (add-hook 'text-mode-hook 'tddsg--hook-prog-text-mode)
  (add-hook 'prog-mode-hook 'tddsg--hook-prog-mode)
  (add-hook 'text-mode-hook 'tddsg--hook-text-mode)
  (add-hook 'change-major-mode-hook 'tddsg--hook-change-major-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INIT KEYS

(defun tddsg/init-keys ()
  ;; unbind some weird keys
  (global-set-key (kbd "<home>") 'crux-move-beginning-of-line)
  (global-set-key (kbd "<escape>") 'god-mode-all)
  (global-set-key (kbd "<f5>") (kbd "C-c C-c C-j"))

  (global-set-key (kbd "C-<backspace>") 'backward-kill-word)
  (global-set-key (kbd "C-<delete>") 'kill-word)
  (global-set-key (kbd "C-<left>") 'left-word)
  (global-set-key (kbd "C-<right>") 'right-word)
  (global-set-key (kbd "C-+") 'zoom-in)
  (global-set-key (kbd "C--") 'zoom-out)
  (global-set-key (kbd "C-`") 'goto-last-change)
  (global-set-key (kbd "C-'") 'other-window)
  (global-set-key (kbd "C-j") 'avy-goto-word-1)
  (global-set-key (kbd "C-o") 'helm-semantic-or-imenu)
  (global-set-key (kbd "C-q") 'goto-last-change)
  (global-set-key (kbd "C-a") 'crux-move-beginning-of-line)
  (global-set-key (kbd "C-z") 'save-buffer)
  (global-set-key (kbd "C-/") 'undo)
  (global-set-key (kbd "C-;") 'iedit-mode)
  (global-set-key (kbd "C-^") 'tddsg/join-with-beneath-line)
  (global-set-key (kbd "C-_") 'tddsg/join-to-above-line)
  (global-set-key (kbd "C-\\") 'sp-split-sexp)

  (global-set-key (kbd "C-S-<backspace>") 'kill-whole-line)
  (global-set-key (kbd "C-S-k") 'kill-whole-line)
  (global-set-key (kbd "C-S-/") 'undo-tree-redo)
  (global-set-key (kbd "C-M-o") 'helm-imenu-anywhere)
  (global-set-key (kbd "C-M-k") 'tddsg/smart-kill-sexp-forward)
  (global-set-key (kbd "C-M-S-k") 'tddsg/smart-kill-sexp-backward)
  (global-set-key (kbd "C-M-j") 'tddsg/join-with-beneath-line)
  (global-set-key (kbd "C-M-i") 'tddsg/join-to-above-line)
  (global-set-key (kbd "C-M-SPC") 'tddsg/mark-sexp-forward)
  (global-set-key (kbd "C-M-S-SPC") 'tddsg/mark-sexp-backward)
  (global-set-key (kbd "C-M-_") 'flip-frame)
  (global-set-key (kbd "C-M-+") 'flop-frame)
  (global-set-key (kbd "C-M-;") 'tddsg/comment-paragraph)

  (global-set-key (kbd "C-x b") 'helm-mini)
  (global-set-key (kbd "C-x t") 'transpose-paragraphs)
  (global-set-key (kbd "C-x _") 'shrink-window)
  (global-set-key (kbd "C-x m") 'monky-status)
  (global-set-key (kbd "C-x g") 'magit-status)
  (global-set-key (kbd "C-x {") 'tddsg/shrink-window-horizontally)
  (global-set-key (kbd "C-x }") 'tddsg/enlarge-window-horizontally)
  (global-set-key (kbd "C-x _") 'tddsg/shrink-window-vertically)
  (global-set-key (kbd "C-x ^") 'tddsg/enlarge-window-vertically)
  (global-set-key (kbd "C-x w s") 'tddsg/save-file-as-and-open-file)

  (global-set-key (kbd "C-x C-d") 'helm-dired-history-view)
  (global-set-key (kbd "C-x C-b") 'switch-to-buffer)
  (global-set-key (kbd "C-x C-f") 'helm-find-files)
  (global-set-key (kbd "C-x C-z") nil)

  (global-set-key [?\H-M] 'helm-mini)
  (global-set-key [?\H-m] 'helm-mini)
  (global-set-key [?\H-i] 'swiper)
  (global-set-key [?\H-I] 'swiper)

  (global-set-key (kbd "C-c f") 'projectile-find-file)
  (global-set-key (kbd "C-c k") 'kill-this-buffer)
  (global-set-key (kbd "C-c o") 'helm-occur)
  (global-set-key (kbd "C-c e") 'ediff)
  (global-set-key (kbd "C-c i") 'ivy-resume)
  (global-set-key (kbd "C-c j") 'avy-resume)
  (global-set-key (kbd "C-c h") 'helm-resume)
  (global-set-key (kbd "C-c s") 'swiper)
  (global-set-key (kbd "C-c r") 'projectile-replace)
  (global-set-key (kbd "C-c R") 'projectile-replace-regexp)
  (global-set-key (kbd "C-c g") 'tddsg/helm-do-ag)
  (global-set-key (kbd "C-c d") 'tddsg/duplicate-region-or-line)
  (global-set-key (kbd "C-c t") 'tddsg/term-current-window)
  (global-set-key (kbd "C-c m") 'tddsg/shell-current-window)

  (global-set-key (kbd "C-c C-c") 'tddsg/compile)
  (global-set-key (kbd "C-c C-g") 'helm-projectile-ag)
  (global-set-key (kbd "C-c C-k") 'kill-matching-buffers)
  (global-set-key (kbd "C-c C-SPC") 'helm-all-mark-rings)

  (global-set-key (kbd "M-SPC") 'tddsg/one-space-or-blank-line)
  (global-set-key (kbd "M-<backspace>") 'backward-kill-word)
  (global-set-key (kbd "M-<delete>") 'kill-word)
  (global-set-key (kbd "M-w") 'tddsg/kill-ring-save)
  (global-set-key (kbd "M-y") 'helm-show-kill-ring)
  (global-set-key (kbd "M-p") 'backward-paragraph)
  (global-set-key (kbd "M-n") 'forward-paragraph)
  ;; (global-set-key (kbd "M-j") 'tddsg/join-to-above-line)
  (global-set-key (kbd "M-D") 'backward-kill-word)
  (global-set-key (kbd "M-k") 'crux-kill-line-backwards)
  (global-set-key (kbd "M-K") 'backward-delete-char-untabify)
  (global-set-key (kbd "M-/") 'hippie-expand)
  (global-set-key (kbd "M-'") 'other-window)
  (global-set-key (kbd "M--") 'delete-window)
  (global-set-key (kbd "M-+") 'delete-other-windows)
  (global-set-key (kbd "M--") 'delete-window)
  (global-set-key (kbd "M-_") 'split-window-below)
  (global-set-key (kbd "M-|") 'split-window-right)
  (global-set-key (kbd "M-=") 'transpose-frame)
  (global-set-key (kbd "M-\\") 'sp-splice-sexp)
  (global-set-key (kbd "M-;") 'comment-dwim-2)
  (global-set-key (kbd "C-M-/") 'company-complete)
  (global-set-key (kbd "C-M-?") 'helm-company)
  (global-set-key (kbd "M-H") 'tddsg/mark-line)
  (global-set-key (kbd "M-h") 'tddsg/mark-paragraph)

  (global-set-key (kbd "M-[") 'windmove-left)
  (global-set-key (kbd "M-]") 'windmove-right)
  (global-set-key (kbd "H-[") 'windmove-up)
  (global-set-key (kbd "C-]") 'windmove-down)

  (global-set-key (kbd "H-M-[") 'previous-buffer)
  (global-set-key (kbd "C-M-]") 'next-buffer)
  (global-set-key (kbd "C-M-{") 'winner-undo)
  (global-set-key (kbd "C-M-}") 'winner-redo)

  (global-set-key (kbd "M-S-<up>") 'move-text-up)
  (global-set-key (kbd "M-S-<down>") 'move-text-down)
  (global-set-key (kbd "M-S-SPC") 'delete-blank-lines)

  (define-key spacemacs-default-map-root-map (kbd "M-m l") nil)

  (global-set-key (kbd "M-m d r") 'diredp-dired-recent-dirs)
  (global-set-key (kbd "M-m f p") 'tddsg/show-and-copy-path-current-buffer)
  (global-set-key (kbd "M-m h g") 'helm-do-grep-ag)
  (global-set-key (kbd "M-m h o") 'helm-occur)
  (global-set-key (kbd "M-m h s") 'helm-semantic-or-imenu)
  (global-set-key (kbd "M-m s d") 'dictionary-search)
  (global-set-key (kbd "M-m S i") 'ispell-buffer)
  (global-set-key (kbd "M-m S s") 'ispell-continue)
  (global-set-key (kbd "M-m S p") 'flyspell-correct-previous-word-generic)
  (global-set-key (kbd "M-m S c") 'flyspell-correct-word-before-point)
  (global-set-key (kbd "M-m m S") 'shell)
  (global-set-key (kbd "M-m m s") 'tddsg/shell-other-window)
  (global-set-key (kbd "M-m l c") 'langtool-check)
  (global-set-key (kbd "M-m l b") 'langtool-correct-buffer)
  (global-set-key (kbd "M-m l d") 'langtool-check-done)
  (global-set-key (kbd "M-m l n") 'langtool-goto-next-error)
  (global-set-key (kbd "M-m l p") 'langtool-goto-previous-error)
  (global-set-key (kbd "M-m l v") 'visual-line-mode)
  (global-set-key (kbd "M-m w t") 'transpose-frame)
  (global-set-key (kbd "M-m w o") 'flop-frame)
  (global-set-key (kbd "M-m w i") 'flip-frame)
  (global-set-key (kbd "M-m T l") 'tddsg/toggle-show-mode-line)
  (global-set-key (kbd "M-m T h") 'tddsg/toggle-show-header-line)

  (global-set-key (kbd "M-s r") 'spacemacs/evil-search-clear-highlight)
  (global-set-key (kbd "M-s i") 'ispell-buffer)
  (global-set-key (kbd "M-s s") 'ispell-continue)
  (global-set-key (kbd "M-s f") 'flyspell-buffer)
  (global-set-key (kbd "M-s p") 'flyspell-correct-previous-word-generic)
  (global-set-key (kbd "M-s c") 'flyspell-correct-word-before-point)
  (global-set-key (kbd "M-s n") 'flyspell-goto-next-error)
  (global-set-key (kbd "M-s k") 'sp-splice-sexp-killing-around)

  ;; workspaces transient
  (global-set-key (kbd "M-m 1") 'eyebrowse-switch-to-window-config-1)
  (global-set-key (kbd "M-m 2") 'eyebrowse-switch-to-window-config-2)
  (global-set-key (kbd "M-m 3") 'eyebrowse-switch-to-window-config-3)
  (global-set-key (kbd "M-m 4") 'eyebrowse-switch-to-window-config-4)
  (global-set-key (kbd "M-m 5") 'eyebrowse-switch-to-window-config-5)
  (global-set-key (kbd "M-m 6") 'eyebrowse-switch-to-window-config-6)
  (global-set-key (kbd "M-m 7") 'eyebrowse-switch-to-window-config-7)
  (global-set-key (kbd "M-m 8") 'eyebrowse-switch-to-window-config-8)
  (global-set-key (kbd "M-m 9") 'eyebrowse-switch-to-window-config-9)
  (global-set-key (kbd "M-m 0") 'eyebrowse-switch-to-window-config-0)
  (global-set-key (kbd "s-+") 'eyebrowse-next-window-config)
  (global-set-key (kbd "s--") 'eyebrowse-prev-window-config)
  (global-set-key (kbd "C-x M-<right>") 'eyebrowse-next-window-config)
  (global-set-key (kbd "C-x M-<left>") 'eyebrowse-prev-window-config)

  ;; layout
  (global-set-key (kbd "M-m l") nil)  ;; disable key "M-m l" first
  (global-set-key (kbd "M-m l m") 'spacemacs/layouts-transient-state/body)
  (global-set-key
   (kbd "M-m l s")
   'spacemacs/layouts-transient-state/persp-save-state-to-file-and-exit)
  (global-set-key
   (kbd "M-m l l")
   'spacemacs/layouts-transient-state/persp-load-state-from-file-and-exit)

  ;; isearch
  (define-key isearch-mode-map (kbd "C-.")
    'tddsg/yank-current-word-to-isearch-buffer)
  (define-key isearch-mode-map (kbd "C-c C-v")
    'pdf-isearch-sync-backward-current-match)
  (define-key isearch-mode-map (kbd "<f6>")
    'pdf-isearch-sync-backward-current-match)

  (define-key swiper-map (kbd "C-.")
    'tddsg/yank-current-word-to-minibuffer)

  ;; minibuffer
  (define-key minibuffer-local-map (kbd "C-.")
    'tddsg/yank-current-word-to-minibuffer)
  (define-key minibuffer-local-map (kbd "C-M-i") nil)

  ;; elisp-mode
  (define-key emacs-lisp-mode-map (kbd "C-M-i") nil)

  ;; shell
  (define-key shell-mode-map (kbd "C-c C-l") 'helm-comint-input-ring)
  (define-key shell-mode-map (kbd "C-c C-s")
    'tddsg/toggle-shell-scroll-to-bottomon-on-output)

  ;; undo tree
  (define-key undo-tree-map (kbd "C-_") nil)
  (define-key undo-tree-map (kbd "M-_") nil)

  ;; magit
  (require 'magit)
  (define-key magit-mode-map (kbd "M-1") nil)
  (define-key magit-mode-map (kbd "M-2") nil)
  (define-key magit-mode-map (kbd "M-3") nil)
  (define-key magit-mode-map (kbd "M-4") nil)
  (define-key magit-mode-map (kbd "M-5") nil)
  (define-key magit-mode-map (kbd "M-6") nil)
  (define-key magit-mode-map (kbd "M-7") nil)
  (define-key magit-mode-map (kbd "M-8") nil)
  (define-key magit-mode-map (kbd "M-9") nil)
  (define-key magit-mode-map (kbd "M-0") nil)
  (define-key magit-status-mode-map (kbd "M-1") nil)
  (define-key magit-status-mode-map (kbd "M-2") nil)
  (define-key magit-status-mode-map (kbd "M-3") nil)
  (define-key magit-status-mode-map (kbd "M-4") nil)
  (define-key magit-status-mode-map (kbd "M-5") nil)
  (define-key magit-status-mode-map (kbd "M-6") nil)
  (define-key magit-status-mode-map (kbd "M-7") nil)
  (define-key magit-status-mode-map (kbd "M-8") nil)
  (define-key magit-status-mode-map (kbd "M-9") nil)
  (define-key magit-status-mode-map (kbd "M-0") nil)

  ;; god-mode
  (define-key isearch-mode-map (kbd "<escape>") 'god-mode-isearch-activate)
  (define-key god-mode-isearch-map (kbd "<escape>") 'god-mode-isearch-disable)
  (define-key god-local-mode-map (kbd "<escape>") 'god-mode-all)
  (define-key god-local-mode-map (kbd "i") 'god-mode-all)

  ;; windmove
  (global-set-key (kbd "S-<left>") 'windmove-left)
  (global-set-key (kbd "S-<right>") 'windmove-right)
  (global-set-key (kbd "S-<up>") 'windmove-up)
  (global-set-key (kbd "S-<down>") 'windmove-down)

  ;; buffer-move
  (global-set-key (kbd "C-S-<left>") 'buf-move-left)
  (global-set-key (kbd "C-S-<right>") 'buf-move-right)
  (global-set-key (kbd "C-S-<up>") 'buf-move-up)
  (global-set-key (kbd "C-S-<down>") 'buf-move-down)
  (define-key spacemacs-default-map-root-map (kbd "M-m b m") nil)
  (global-set-key (kbd "M-m b m b") 'buf-move-left)
  (global-set-key (kbd "M-m b m n") 'buf-move-down)
  (global-set-key (kbd "M-m b m p") 'buf-move-up)
  (global-set-key (kbd "M-m b m f") 'buf-move-right)

  ;; buffer-clone
  (global-set-key (kbd "C-M-S-<left>") 'buf-clone-left)
  (global-set-key (kbd "C-M-S-<right>") 'buf-clone-right)
  (global-set-key (kbd "C-M-S-<up>") 'buf-clone-up)
  (global-set-key (kbd "C-M-S-<down>") 'buf-clone-down)
  (global-set-key (kbd "C-M-s-7") 'buf-clone-left)
  (global-set-key (kbd "C-M-s-8") 'buf-clone-down)
  (global-set-key (kbd "C-M-s-9") 'buf-clone-up)
  (global-set-key (kbd "C-M-s-0") 'buf-clone-right)

  ;; LaTeX-mode
  (define-key TeX-mode-map (kbd "C-o") 'reftex-toc)
  (define-key TeX-mode-map (kbd "<f5>") 'tddsg--latex-compile)
  (define-key TeX-mode-map (kbd "<f6>") 'tddsg--latex-compile-sync-forward)
  (define-key TeX-mode-map (kbd "C-j") nil)
  (define-key TeX-mode-map (kbd "C-M-i") nil)
  (eval-after-load 'latex
    '(progn
       (define-key LaTeX-mode-map (kbd "C-o") 'reftex-toc)
       (define-key LaTeX-mode-map (kbd "C-j") nil)
       (define-key LaTeX-mode-map (kbd "\"") nil)
       (define-key LaTeX-mode-map (kbd "C-c C-g") nil)
       (define-key latex-extra-mode-map (kbd "C-M-f") nil)
       (define-key latex-extra-mode-map (kbd "C-M-b") nil)
       (define-key latex-extra-mode-map (kbd "C-M-n") nil)
       (define-key latex-extra-mode-map (kbd "C-M-p") nil)))

  ;; Python mode
  (define-key python-mode-map (kbd "C-j") nil)

  ;; pdf-tools
  (define-key pdf-view-mode-map (kbd "C-<home>") 'pdf-view-first-page)
  (define-key pdf-view-mode-map (kbd "C-<end>") 'pdf-view-last-page)
  (define-key pdf-view-mode-map (kbd "[") 'pdf-view-previous-line-or-previous-page)
  (define-key pdf-view-mode-map (kbd "]") 'pdf-view-next-line-or-next-page)
  (define-key pdf-view-mode-map (kbd "M-{") 'pdf-view-previous-page-command)
  (define-key pdf-view-mode-map (kbd "M-}") 'pdf-view-next-page-command)
  (define-key pdf-view-mode-map (kbd "M-w") 'tddsg/pdf-view-kill-ring-save)
  (define-key pdf-view-mode-map (kbd "M-SPC")
    'pdf-view-scroll-down-or-previous-page)
  (define-key pdf-view-mode-map (kbd "RET") 'pdf-view-scroll-up-or-next-page)
  (define-key pdf-view-mode-map (kbd "<mouse-8>") 'pdf-history-backward)
  (define-key pdf-view-mode-map (kbd "<mouse-9>") 'pdf-history-forward)


  ;; flyspell
  (define-key flyspell-mode-map (kbd "C-;") nil)
  (define-key flyspell-mode-map (kbd "C-M-i") nil)

  ;; dired mode
  (define-key dired-mode-map (kbd "C-^") 'tddsg/dired-home)
  (define-key dired-mode-map (kbd "M-C") 'tddsg/dired-duplicate-files)

  ;; smartparens
  (define-key smartparens-mode-map (kbd "M-s") nil)

  ;; evil mode
  (define-key evil-normal-state-map (kbd "<remap> <evil-next-line>")
    'evil-next-visual-line)
  (define-key evil-normal-state-map (kbd "<remap> <evil-previous-line>")
    'evil-previous-visual-line)
  (define-key evil-motion-state-map (kbd "<remap> <evil-next-line>")
    'evil-next-visual-line)
  (define-key evil-motion-state-map (kbd "<remap> <evil-previous-line>")
    'evil-previous-visual-line)
  (define-key evil-motion-state-map (kbd "C-i") 'evil-jump-forward)
  (define-key evil-motion-state-map (kbd "C-^") nil)
  (define-key evil-motion-state-map (kbd "C-_") nil)

  ;; company mode
  (define-key company-active-map (kbd "M-d") 'company-show-doc-buffer)
  (define-key company-active-map (kbd "M-.") 'company-show-location)

  ;; reassign key-chords
  (key-chord-define-global "ji" 'indent-region)
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INIT THEMES

(defcustom tddsg-themes nil
  "Association list of override faces to set for different custom themes.")

(defun tddsg--read-custom-themes (alist-symbol key value)
  "Set VALUE of a KEY in ALIST-SYMBOL."
  (set alist-symbol
       (cons (list key value) (assq-delete-all key (eval alist-symbol)))))

;; override some settings of the leuven theme
(defun tddsg--custom-theme-leuven ()
  (tddsg--read-custom-themes
   'tddsg-themes
   'leuven
   '((bold ((t (:foreground "salmon4" :weight bold))))
     (bold-italic ((t (:foreground "salmon4" :slant italic :weight bold))))
     ;; cursors & line
     (cursor ((t (:background "dark orange"))))
     (hl-line ((t (:background "honeydew2"))))
     ;; latex font face
     (font-latex-bold-face ((t (:foreground "gray26" :weight bold))))
     (font-latex-math-face ((t (:foreground "DeepSkyBlue4"))))
     (font-latex-sedate-face ((t (:foreground "green4"))))
     (font-latex-subscript-face ((t (:height 0.96))))
     (font-latex-superscript-face ((t (:height 0.96))))
     (font-latex-verbatim-face ((t (:inherit nil :background "white" :foreground "light coral"))))
     (font-latex-sectioning-0-face ((t (:background "white smoke" :foreground "forest green" :overline t :weight bold :height 1.2))))
     (font-latex-sectioning-1-face ((t (:background "white smoke" :foreground "steel blue" :overline t :weight bold :height 1.2))))
     (font-latex-sectioning-2-face ((t (:background "#F0F0F0" :foreground "royal blue" :overline "#A7A7A7" :weight bold :height 1.1))))
     ;; dired mode
     (diredp-compressed-file-name ((t (:foreground "royal blue"))))
     (diredp-compressed-file-suffix ((t (:foreground "royal blue"))))
     (diredp-ignored-file-name ((t (:foreground "peru"))))
     ;; font lock face
     (font-lock-constant-face ((t (:foreground "dark goldenrod"))))
     (font-lock-doc-face ((t (:foreground "#8959a8"))))
     (font-lock-function-name-face ((t (:foreground "dark orchid" :weight normal))))
     (font-lock-keyword-face ((t (:foreground "blue" :weight normal))))
     (font-lock-string-face ((t (:foreground "#3e999f"))))
     (font-lock-type-face ((t (:foreground "MediumOrchid4" :weight normal))))
     (font-lock-variable-name-face ((t (:foreground "DodgerBlue3" :weight normal))))
     (company-tooltip-common ((t (:inherit company-tooltip :weight bold :underline nil))))
     (company-tooltip-common-selection ((t (:inherit company-tooltip-selection :weight bold :underline nil))))
     ;; others
     (diredp-file-suffix ((t (:foreground "sienna"))))
     (powerline-active1 ((t (:inherit mode-line :background "#163365")))))))

;; override some settings of the spacemacs-dark theme
(defun tddsg--custom-theme-spacemacs-dark ()
  (tddsg--read-custom-themes
   'tddsg-themes
   'spacemacs-dark
   '(;; cursors & line
     (cursor ((t (:background "dark orange"))))
     ;; dired
     (diredp-compressed-file-name ((t (:foreground "burlywood"))))
     (diredp-compressed-file-suffix ((t (:foreground "yellow green"))))
     (diredp-dir-name ((t (:foreground "medium sea green" :weight bold))))
     (diredp-file-name ((t (:foreground "burlywood"))))
     (diredp-file-suffix ((t (:foreground "powder blue"))))
     (diredp-ignored-file-name ((t nil)))
     (diredp-link-priv ((t (:foreground "dodger blue"))))
     (diredp-symlink ((t (:foreground "dodger blue"))))
     ;; hilock
     '(hi-blue ((t (:background "medium blue" :foreground "white smoke"))))
     '(hi-blue-b ((t (:foreground "deep sky blue" :weight bold))))
     '(hi-green ((t (:background "dark olive green" :foreground "white smoke"))))
     '(hi-pink ((t (:background "dark magenta" :foreground "white smoke"))))
     '(hi-red-b ((t (:foreground "red1" :weight bold))))
     '(hi-yellow ((t (:background "dark goldenrod" :foreground "white smoke"))))
     ;; isearch
     '(isearch ((t (:background "dark orange" :foreground "#292b2e"))))
     '(lazy-highlight ((t (:background "LightGoldenrod3" :foreground "gray10" :weight normal))))
     ;; font
     (font-latex-verbatim-face ((t (:inherit fixed-pitch :foreground "olive drab"))))
     (font-latex-sedate-face ((t (:foreground "#64A873" :weight normal))))
     (font-latex-subscript-face ((t (:height 0.9))))
     (font-latex-superscript-face ((t (:height 0.9))))
     (font-latex-sectioning-0-face ((t (:foreground "lawn green" :weight bold :height 1.4))))
     (font-latex-sectioning-1-face ((t (:foreground "deep sky blue" :weight bold :height 1.4))))
     (font-latex-sectioning-2-face ((t (:foreground "royal blue" :weight bold :height 1.2))))
     (lazy-highlight ((t (:background "dark goldenrod" :foreground "gray10" :weight normal))))
     )))

(defun tddsg--custom-common ()
  ;; custom variables
  (custom-set-variables
   '(sp-highlight-wrap-overlay nil))
  ;; custom faces
  (custom-set-faces
   '(sp-pair-overlay-face ((t nil)))
   '(sp-wrap-overlay-face ((t nil)))
   '(sp-wrap-tag-overlay-face ((t nil)))))

(defun tddsg--override-theme ()
  (dolist (theme-settings tddsg-themes)
    (let ((theme (car theme-settings))
          (faces (cadr theme-settings)))
      (if (member theme custom-enabled-themes)
          (dolist (face faces)
            (custom-theme-set-faces theme face))))))

(defun tddsg/init-themes ()
  ;; load the custom theme
  (tddsg--custom-common)
  (tddsg--custom-theme-leuven)
  (tddsg--custom-theme-spacemacs-dark)
  (tddsg--override-theme)
  ;; and defadvice load-theme function
  (defadvice load-theme (after theme-set-overrides activate)
    "Set override faces for different custom themes."
    (tddsg--override-theme)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INIT HEADER LINE

;; https://www.emacswiki.org/emacs/HeaderLine

(defmacro with-face (str &rest properties)
  `(propertize ,str 'face (list ,@properties)))

(defun tddsg--header-file-path ()
  "Create file path for the header line."
  (let* ((file-path (if buffer-file-name
                        (abbreviate-file-name buffer-file-name)
                      (buffer-name)))
         (dir-name  (if buffer-file-name
                        (file-name-directory file-path) ""))
         (file-name  (if buffer-file-name
                         (file-name-nondirectory buffer-file-name)
                       (buffer-name)))
         (path-len (length file-path))
         (name-len (length file-name))
         (dir-len (length dir-name))
         (drop-str "[...]")
         (path-display-len (- (window-body-width)
                              (length (projectile-project-name)) 3))
         (dir-display-len (- path-display-len (length drop-str) name-len 2)))
    (cond ((< path-len path-display-len)
           (concat "▷ "
                   (with-face dir-name :foreground "DeepSkyBlue3")
                   (with-face file-name :foreground "DarkOrange3")))
          ((and (> dir-len dir-display-len) (> dir-display-len 3))
           (concat "▷ "
                   (with-face (substring dir-name 0 (/ dir-display-len 2))
                              :foreground "DeepSkyBlue3")
                   (with-face drop-str :foreground "DeepSkyBlue3")
                   (with-face (substring dir-name
                                         (- dir-len (/ dir-display-len 2))
                                         (- dir-len 1))
                              :foreground "DeepSkyBlue3")
                   (with-face "/" :foreground "DeepSkyBlue3")
                   (with-face file-name :foreground "DarkOrange3")))
          (t (concat "▷ " (with-face file-name :foreground "DarkOrange3"))))))

(defun tddsg--header-project-path ()
  "Create project path for the header line."
  (if (tddsg--projectile-p)
      (concat "♖ "
              (with-face (projectile-project-name) :foreground "DarkOrange3")
              " ")
    ""))

;; set font of header line
(custom-set-faces
 '(header-line
   ((default :inherit mode-line)
    (((type tty))
     :foreground "black" :background "yellow" :inverse-video nil)
    (((class color grayscale) (background light))
     :background "grey90" :foreground "grey20" :box nil)
    (((class color grayscale) (background dark))
     :background "#212026" :foreground "gainsboro" :box nil)
    (((class mono) (background light))
     :background "white" :foreground "black"
     :inverse-video nil :box nil :underline t)
    (((class mono) (background dark))
     :background "black" :foreground "white"
     :inverse-video nil :box nil :underline t))))

(defun tddsg--create-header-line ()
  "Create the header line of a buffer."
  '("" ;; invocation-name
    (:eval
     (concat (tddsg--header-project-path)
             (tddsg--header-file-path)))))

;; List of buffer prefixes that the header-line is hidden
(defvar tddsg--excluded-buffer-prefix (list "*helm"
                                            "*spacemacs*"))

(defun tddsg--header-exclude-p (buffer-name)
  (cl-loop for buffer-prefix in tddsg--excluded-buffer-prefix
           thereis (string-match-p (regexp-quote buffer-prefix) buffer-name)))

(defun tddsg--update-header-line ()
  "Update header line of the active buffer and remove from all other."
  (cl-loop for window in (window-list) do
           (with-current-buffer (window-buffer window)
             (when (not (tddsg--header-exclude-p
                         (buffer-name (window-buffer window))))
               (if (eq (window-buffer window)
                       (window-buffer (selected-window)))
                   ;; activate header-line of the active buffer
                   (setq header-line-format (tddsg--create-header-line))
                 ;; dim header-line of inactive buffers
                 (setq header-line-format
                       `(:propertize ,(tddsg--create-header-line)
                                     face (:foreground "grey55"))))))))

;; update header line of each buffer
(add-hook 'buffer-list-update-hook 'tddsg--update-header-line)
(add-hook 'window-configuration-change-hook 'tddsg--update-header-line)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INIT SPACELINE

;; reuse code from spaceline-config.el
(defun tddsg--create-spaceline-theme (left second-left &rest additional-segments)
  "Convenience function for the spacemacs and emacs themes."
  (spaceline-install 'tddsg
                     `(,left
                       anzu
                       auto-compile
                       ,second-left
                       major-mode
                       (version-control :when active)
                       (minor-modes :when active)
                       (process :when active)
                       ((flycheck-error flycheck-warning flycheck-info)
                        :when active)
                       (mu4e-alert-segment :when active)
                       (erc-track :when active)
                       (org-pomodoro :when active)
                       (org-clock :when active)
                       nyan-cat)
                     `((global :when (not active))
                       which-function
                       (python-pyvenv :fallback python-pyenv)
                       (battery :when active)
                       selection-info
                       ,@additional-segments
                       input-method
                       (buffer-encoding-abbrev :when active)
                       (buffer-position :when active)
                       hud))
  (setq-default mode-line-format '("%e" (:eval (spaceline-ml-tddsg)))))

;;; used for setting pdf-view page
;;; FIXME: to be removed when spaceline is updated
(declare-function pdf-view-current-page 'pdf-view)
(declare-function pdf-cache-number-of-pages 'pdf-view)

(defun tddsg--pdfview-page-number ()
  (format "(%d/%d)"
          (eval (pdf-view-current-page))
          (pdf-cache-number-of-pages)))

(spaceline-define-segment line-column
  "The current line and column numbers, or `(current page/number of pages)`
in pdf-view mode (enabled by the `pdf-tools' package)."
  (if (eq 'pdf-view-mode major-mode)
      (tddsg--pdfview-page-number)
    "%l:%2c"))


(defun tddsg--create-spaceline-final (&rest additional-segments)
  "Install the modeline used by Spacemacs.

ADDITIONAL-SEGMENTS are inserted on the right, between `global' and
`buffer-position'."
  (apply 'tddsg--create-spaceline-theme
         '((persp-name
            workspace-number
            window-number)
           :fallback evil-state
           :separator "|"
           :face highlight-face)
         '(buffer-modified
           point-position
           line-column
           ;; buffer-size
           buffer-id
           remote-host)
         additional-segments))

(dolist (s '((tddsg-face-unmodified "SteelBlue3"
                                    "Unmodified buffer face.")
             (tddsg-face-modified "DarkGoldenrod2"
                                  "Modified buffer face.")
             (tddsg-face-read-only "SteelBlue3"
                                   "Read-only buffer face.")))
  (eval `(defface, (nth 0 s)
           `((t (:background ,(nth 1 s)
                             :foreground "#3E3D31"
                             :inherit 'mode-line)))
           ,(nth 2 s)
           :group 'tddsg)))


(defun tddsg--spaceline-highlight-face ()
  "Set the highlight face depending on the buffer modified status.
Set `spaceline-highlight-face-func' to
`tddsg--spaceline-highlight-face' to use this."
  (cond
   (buffer-read-only 'tddsg-face-read-only)
   ((buffer-modified-p) 'tddsg-face-modified )
   (t 'tddsg-face-unmodified)))


(defun tddsg/init-spaceline ()
  (setq spaceline-highlight-face-func 'tddsg--spaceline-highlight-face)
  (tddsg--create-spaceline-final))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; INIT CUSTOM

(defun tddsg/init-custom-vars ()
  (custom-set-variables
   '(golden-ratio-exclude-buffer-names
     (quote
      ("*which-key*"
       "*LV*"
       "*NeoTree*"
       "*ace-popup-menu*"
       "*compilation*")))
   '(LaTeX-indent-environment-list
     (quote
      (("verbatim" current-indentation)
       ("verbatim*" current-indentation)
       ("longtable" LaTeX-indent-tabular)
       ("Form" current-indentation)
       ("tabular")
       ("tabular*")
       ("align")
       ("align*")
       ("array")
       ("eqnarray")
       ("eqnarray*")
       ("displaymath")
       ("equation")
       ("equation*")
       ("picture")
       ("tabbing")
       ("figure")
       ("center")
       ("flushleft")
       ("flushright")
       ("small"))))
   '(pdf-view-continuous nil)
   '(hl-todo-keyword-faces
     (quote
      (("HOLD" . "red")
       ("TODO" . "red")
       ("NEXT" . "red")
       ("OKAY" . "red")
       ("DONT" . "red")
       ("FAIL" . "red")
       ("DONE" . "red")
       ("NOTE" . "red")
       ("HACK" . "red")
       ("FIXME" . "red")
       ("XXX" . "red")
       ("XXXX" . "red")
       ("???" . "red")
       ("BUG" . "red")
       ("OK" . "red"))))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; FINALLY, OVERRIDE OTHER EMACS'S FUNCTION

;;;;; POPWIN mode

(require 'popwin)
(defun* popwin:popup-buffer (buffer
                             &key
                             (width popwin:popup-window-width)
                             (height popwin:popup-window-height)
                             (position popwin:popup-window-position)
                             noselect
                             dedicated
                             stick
                             tail)
  "Show BUFFER in a popup window and return the popup window. If
NOSELECT is non-nil, the popup window will not be selected. If
STICK is non-nil, the popup window will be stuck. If TAIL is
non-nil, the popup window will show the last contents. Calling
`popwin:popup-buffer' during `popwin:popup-buffer' is allowed. In
that case, the buffer of the popup window will be replaced with
BUFFER."
  (interactive "BPopup buffer:\n")
  (setq buffer (get-buffer buffer))
  (popwin:push-context)
  (run-hooks 'popwin:before-popup-hook)
  (multiple-value-bind (context context-stack)
      (popwin:find-context-for-buffer buffer :valid-only t)
    (if context
        (progn
          (popwin:use-context context)
          (setq popwin:context-stack context-stack))
      (let ((win-outline (car (popwin:window-config-tree))))
        (destructuring-bind (master-win popup-win win-map)
            (let ((size (if (popwin:position-horizontal-p position) width height))
                  (adjust popwin:adjust-other-windows))
              ;; <-- original line
              ;; (popwin:create-popup-window size position adjust)
              ;; <-- new code
              (let* ((popup-win-height (- popwin:popup-window-height))
                     (orig-window (selected-window))
                     (new-window (split-window orig-window popup-win-height 'below)))
                (set-window-buffer new-window buffer)
                (list orig-window new-window nil))
              )
          (setq popwin:popup-window popup-win
                popwin:master-window master-win
                popwin:window-outline win-outline
                popwin:window-map win-map
                popwin:window-config nil
                popwin:selected-window (selected-window)))
        (popwin:update-window-reference 'popwin:context-stack :recursive t)
        (popwin:start-close-popup-window-timer))
      (with-selected-window popwin:popup-window
        (popwin:switch-to-buffer buffer)
        (when tail
          (set-window-point popwin:popup-window (point-max))
          (recenter -2)))
      (setq popwin:popup-buffer buffer
            popwin:popup-last-config (list buffer
                                           :width width :height height :position position
                                           :noselect noselect :dedicated dedicated
                                           :stick stick :tail tail)
            popwin:popup-window-dedicated-p dedicated
            popwin:popup-window-stuck-p stick)))
  (if noselect
      (setq popwin:focus-window popwin:selected-window)
    (setq popwin:focus-window popwin:popup-window)
    (select-window popwin:popup-window))
  (run-hooks 'popwin:after-popup-hook)
  popwin:popup-window)

;;; customize helm-ag
(defsubst helm-ag--marked-input ()
  (when (use-region-p)
    (let* ((text (buffer-substring-no-properties (region-beginning) (region-end)))
           (text (replace-regexp-in-string " " "\\\\ " text)))
      (deactivate-mark)
      text)))


;;;;; PDF-VIEW MODE

(require 'pdf-view)
(require 'pdf-isearch)
(require 'pdf-sync)

;;;;; customize to jump to the pdf-view window and display tooltip
(defun pdf-sync-forward-search (&optional line column)
  "Display the PDF location corresponding to LINE, COLUMN."
  (interactive)
  (cl-destructuring-bind (pdf page _x1 y1 _x2 _y2)
      (pdf-sync-forward-correlate line column)
    (let ((buffer (or (find-buffer-visiting pdf)
                      (find-file-noselect pdf))))
      (select-window (display-buffer buffer pdf-sync-forward-display-action))
      (other-window -1)
      (other-window 1)
      (pdf-util-assert-pdf-window)
      (pdf-view-goto-page page)
      (let ((top (* y1 (cdr (pdf-view-image-size)))))
        (run-at-time 0.02 nil
                     (lambda (top)
                       ;; display tooltip by a timer to avoid being cleared
                       (pdf-util-tooltip-arrow (round top) 20))
                     top)
        ;;; old code
        ;; (pdf-util-tooltip-arrow (round top) 20)
        )
      (with-current-buffer buffer (run-hooks 'pdf-sync-forward-hook)))))

;;;;;; customize pdf-isearch for syncing backward
(defun pdf-isearch-sync-backward-current-match ()
  "Sync backward to the LaTeX source of the current match."
  (interactive)
  (if pdf-isearch-current-match
      (let ((left (caar pdf-isearch-current-match))
            (top (cadar pdf-isearch-current-match)))
        (isearch-exit)
        (funcall 'pdf-sync-backward-search left top))))



;;;;;;;; override golden-ratio-mode

(defcustom golden-ratio-adjust-factor-height 1.1
  "Adjust the height sizing by some factor. 1 is no adjustment."
  :group 'golden-ratio
  :type 'integer)

(defun golden-ratio--scale-factor-height ()
  golden-ratio-adjust-factor-height)

(defun golden-ratio--dimensions ()
  (list (floor (* (/ (frame-height) golden-ratio--value)
                  (golden-ratio--scale-factor-height)))
        (floor (* (/ (frame-width)  golden-ratio--value)
                   (golden-ratio--scale-factor)))))

;;;;;;; REASON MODE ;;;;;;;;

(defun tddsg/init-reason-mode ()
  (defun chomp-end (str)
    "Chomp tailing whitespace from STR."
    (replace-regexp-in-string (rx (* (any " \t\n")) eos)
                              ""
                              str))
  (defun my-reason-hook ()
    (add-hook 'before-save-hook 'refmt-before-save)
    (merlin-mode)
    (merlin-use-merlin-imenu))

  (let ((support-base-dir (concat (replace-regexp-in-string "refmt" "" (file-truename (chomp-end (shell-command-to-string "which refmt")))) ".."))
        (merlin-base-dir (concat (replace-regexp-in-string "ocamlmerlin" "" (file-truename (chomp-end (shell-command-to-string "which ocamlmerlin")))) "..")))
    ;; Add npm merlin.el to the emacs load path and tell emacs where to find ocamlmerlin
    (add-to-list 'load-path (concat merlin-base-dir "/share/emacs/site-lisp/"))
    (setq merlin-command (concat merlin-base-dir "/bin/ocamlmerlin"))

    ;; Add npm reason-mode to the emacs load path and tell emacs where to find refmt
    (add-to-list 'load-path (concat support-base-dir "/share/emacs/site-lisp"))
    (setq refmt-command (concat support-base-dir "/bin/refmt")))

  (require 'reason-mode)
  (require 'merlin)
  (setq merlin-ac-setup t)
  (add-hook 'reason-mode-hook 'my-reason-hook))
