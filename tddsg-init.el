(defun tddsg/shell-other-window (&optional buffer)
  "Open a `shell' in a new window."
  (interactive)
  (let ((old-buf (current-buffer))
        (current-prefix-arg 4) ;; allow using C-u
        (shell-buf (call-interactively 'shell)))
    (switch-to-buffer-other-window shell-buf)
    (switch-to-buffer old-buf)
    (other-window 1)))

(defun tddsg/shell-current-window (&optional buffer)
  "Open a `shell' in the current window."
  (interactive)
  (let ((old-buf (if (= (count-windows) 1) (current-buffer)
                   (progn
                     (other-window 1)
                     (let ((buf (window-buffer))) (other-window -1) buf))))
        (old-window (frame-selected-window))
        (current-prefix-arg 4) ;; allow using C-u
        (shell-buf (call-interactively 'shell)))
    (switch-to-buffer old-buf)
    (select-window old-window)
    (switch-to-buffer shell-buf)))

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

(defun tddsg/mark-line ()
  "Select current line"
  (interactive)
  (end-of-line)
  (set-mark (line-beginning-position)))

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

(defun tddsg/unpop-to-mark-command ()
  "Unpop off mark ring. Does nothing if mark ring is empty."
  (interactive)
  (when mark-ring
    (setq mark-ring (cons (copy-marker (mark-marker)) mark-ring))
    (set-marker (mark-marker) (car (last mark-ring)) (current-buffer))
    (when (null (mark t)) (ding))
    (setq mark-ring (nbutlast mark-ring))
    (goto-char (marker-position (car (last mark-ring))))))


(defun tddsg-set-mark ()
  (interactive)
  (push-mark (point) t nil))

(defun tddsg-hook-prog-text-mode ()
  (linum-mode 1)
  (column-marker-1 80)
  (whitespace-mode 1))

(defun tddsg-hook-prog-mode ()
  (flycheck-mode 1))

(defun tddsg-hook-text-mode ()
  (flyspell-mode 1))

(defun tddsg/init-configs ()
  ;; visual interface setting
  (add-hook 'prog-mode-hook 'tddsg-hook-prog-text-mode)
  (add-hook 'text-mode-hook 'tddsg-hook-prog-text-mode)
  (add-hook 'prog-mode-hook 'tddsg-hook-prog-mode)
  (add-hook 'text-mode-hook 'tddsg-hook-text-mode)
  (setq-default fill-column 80)
  (setq text-scale-mode-step 1.1)                     ; scale changing font size
  (setq frame-title-format                            ; frame title
        '("" invocation-name " - "
          (:eval (if (buffer-file-name)
                     (abbreviate-file-name (buffer-file-name)) "%b"))))

  ;; mode paragraph setting
  (setq paragraph-separate "[ \t\f]*$"
        paragraph-start "\f\\|[ \t]*$")

  ;; mode electric-pair
  (electric-pair-mode t)

  ;; company mode
  ;; (setq company-idle-delay 200)          ;; setdelaytimebydefault
  (global-company-mode)

  ;; spell
  (setq ispell-program-name "aspell" ; use aspell instead of ispell
        ispell-extra-args '("--sug-mode=ultra")
        ispell-dictionary "english"
        prelude-flyspell nil)

  ;; automatically setting mark for certain commands
  (setq global-mark-ring-max 1000
        mark-ring-max 200)
  (defadvice find-file (before set-mark activate) (tddsg-set-mark))
  (defadvice isearch-update (before set-mark activate) (tddsg-set-mark))
  (defadvice beginning-of-buffer (before set-mark activate) (tddsg-set-mark))
  (defadvice end-of-buffer (before set-mark activate) (tddsg-set-mark))
  (defadvice merlin-locate (before set-mark activate) (tddsg-set-mark))

  ;; mode editing setting
  (delete-selection-mode t)                           ; delete selection by keypress
  (setq require-final-newline t)                      ; newline at end of file
  (defadvice newline                                  ; indent after new line
      (after newline-after activate)
    (indent-according-to-mode))

  ;; some Emacs threshold
  (setq max-lisp-eval-depth 10000)
  (setq max-specpdl-size 10000)

  ;; mode-line setting
  (setq powerline-default-separator 'wave)

  ;; fix page-up/page-down problems in smooth-scroll
  (setq scroll-conservatively 101
        scroll-margin 3
        scroll-preserve-screen-position 't)

  ;; diminish
  (eval-after-load "abbrev" '(diminish 'abbrev-mode " ↹"))
  (eval-after-load "whitespace" '(diminish 'whitespace-mode " S"))
  (eval-after-load "whitespace-mode" '(diminish 'whitespace-mode " R"))
  (eval-after-load "smartparens" '(diminish 'smartparens-mode " ♓"))
  (eval-after-load "super-save" '(diminish 'super-save-mode " ⓢ"))
  (eval-after-load "god-mode" '(diminish 'god-local-mode " ☼"))
  (eval-after-load "which-key" '(diminish 'which-key-mode " ⌨"))
  (eval-after-load "rainbow-mode" '(diminish 'rainbow-mode " ☔"))
  (eval-after-load "autorevert" '(diminish 'auto-revert-mode " ↺"))
  (eval-after-load "visual-line" (diminish 'visual-line-mode " ⤾"))
  (eval-after-load "merlin" '(diminish 'merlin-mode " ☮"))
  (eval-after-load "flycheck" '(diminish 'flycheck-mode " ✔"))
  (eval-after-load "flyspell" '(diminish 'flyspell-mode " ✔"))
  (eval-after-load "projectile" '(diminish 'projectile-mode " π")))


(defun tddsg/init-keys ()
  (global-set-key (kbd "<home>") 'spacemacs/smart-move-beginning-of-line)
  (global-set-key (kbd "<detete>") 'delete-forward-char)
  (global-set-key (kbd "C-S-<backspace>") 'kill-whole-line)
  (global-set-key (kbd "C-M-k") 'sp-kill-sexp)
  (global-set-key (kbd "C-<left>") 'left-word)
  (global-set-key (kbd "C-<right>") 'right-word)
  (global-set-key (kbd "C-+") 'text-scale-increase)
  (global-set-key (kbd "C--") 'text-scale-decrease)
  (global-set-key (kbd "C-/") 'undo)
  (global-set-key (kbd "C-S-/") 'undo-tree-redo)
  (global-set-key (kbd "C-^") 'crux-top-join-line)
  (global-set-key (kbd "C-_") 'join-line)
  (global-set-key (kbd "C-a") 'crux-move-beginning-of-line)
  (global-set-key (kbd "C-c d") 'crux-duplicate-current-line-or-region)

  (global-set-key (kbd "C-x _") 'shrink-window)
  (global-set-key (kbd "C-x m") 'monky-status)
  (global-set-key (kbd "C-x g") 'magit-status)
  (global-set-key (kbd "C-x G") 'magit-diff)

  (global-set-key (kbd "C-c C-w") 'tddsg/save-file-as-and-open-file)
  (global-set-key (kbd "C-c C-SPC") 'tddsg/unpop-to-mark-command)
  (global-set-key (kbd "C-c m") 'tddsg/shell-other-window)
  (global-set-key (kbd "C-c M-m") 'tddsg/shell-current-window)

  (global-set-key (kbd "M-S-<up>") 'move-text-up)
  (global-set-key (kbd "M-S-<down>") 'move-text-down)
  (global-set-key (kbd "M-s p") 'check-parens)
  (global-set-key (kbd "M-/") 'hippie-expand)
  (global-set-key (kbd "M-;") 'comment-dwim-2)
  (global-set-key (kbd "M-?") 'company-complete)
  (global-set-key (kbd "M-H") 'tddsg/mark-line)
  (global-set-key (kbd "M-[") 'helm-company)
  (global-set-key (kbd "M-]") 'helm-dabbrev)

  (global-set-key (kbd "M-m h o") 'helm-occur)
  (global-set-key (kbd "M-m h s") 'helm-semantic-or-imenu)
  (global-set-key (kbd "M-m S s") 'flyspell-mode)
  (global-set-key (kbd "M-m w t") 'transpose-frame)

  (global-set-key (kbd "C-s-S-<left>") 'buf-move-left)
  (global-set-key (kbd "C-s-S-<right>") 'buf-move-right)
  (global-set-key (kbd "C-s-S-<up>") 'buf-move-up)
  (global-set-key (kbd "C-s-S-<down>") 'buf-move-down)

  (global-set-key (kbd "<home>") 'crux-move-beginning-of-line)

  (define-key isearch-mode-map (kbd "C-.") 'tddsg/yank-current-word-to-isearch-buffer)
  (define-key minibuffer-local-map (kbd "C-.") 'tddsg/yank-current-word-to-minibuffer)
  (define-key shell-mode-map (kbd "C-j") 'newline)
  (define-key undo-tree-map (kbd "C-_") nil)

  (define-key company-active-map (kbd "M-n") nil)
  (define-key company-active-map (kbd "M-p") nil)
  (define-key company-active-map (kbd "\C-d") 'company-show-doc-buffer)
  (define-key company-active-map (kbd "M-.") 'company-show-location)
  (define-key company-active-map (kbd "C-n") #'company-select-next)
  (define-key company-active-map (kbd "C-p") #'company-select-previous)
  )