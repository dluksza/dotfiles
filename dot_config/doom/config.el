;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Dariusz Luksza"
      user-mail-address "dariusz.luksza@gmail.com")


;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "Fira Code" :size 13 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 14))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-dracula)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
;; COMMENDED
;; (setq org-directory "~/org/"
;;       org-agenda-files "~/org/agenda.org"
;;       org-log-done 'time)


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; MY CONFIGURATION ;;
(setq flycheck-emacs-lisp-load-path 'inherit)

(add-hook 'focus-out-hook
          (lambda ()
            (unless (eq 'evil-mode 'normal)
              (dolist (buffer (buffer-list))
                (set-buffer buffer)
                (unless (or (minibufferp)
                            (eq evil-state 'emacs))
                  (evil-force-normal-state)))
              (message "Dropped back to normal state in all buffers"))))

(super-save-mode +1)

(setq ispell-program-name "hunspell"
      ispell-extra-args '("--sug-mode=ultra" "--lang=en_GB")
      ispell-dictionary "en")

(after! company
  (setq company-minimum-prefix-length 2)
  (setq company-show-quick-access t))

(display-fill-column-indicator-mode)

(setq
 scroll-margin 10
 display-fill-column-indicator-column 120
 auto-save-default nil
 super-save-auto-save-when-idle t
 make-backup-files t
 dart-format-on-save t
 web-mode-markup-indent-offset 2
 web-mode-code-indent-offset 2
 web-mode-css-indent-offset 2
 json-reformat:indent-width 2
 typescript-indent-level 2
 css-indent-offset 2
 js-indent-level 2
 electric-pair-mode t
 electric-quote-mode t
 electric-indent-mode t
 ;; mac-command-modifier 'meta
 projectile-project-search-path '("~/workspace/")
 lsp-dart-sdk-dir (expand-file-name "~/fvm/default/bin/cache/dart-sdk")
 lsp-dart-flutter-sdk-dir (expand-file-name "~/fvm/default")
 lsp-dart-dap-flutter-hot-reload-on-save t
 ;; lsp-dart-sdk-dir "~/fvm/default"
 lsp-dart-dap-flutter-hot-reload-on-save t
 evil-want-Y-yank-to-eol t)

(set-electric! 'dart-mode)
(set-electric! 'lsp-mode)
(set-electric! 'typescript-mode)

(set-company-backend!
  '(text-mode
    markdown-mode
    gfm-mode
    dart-mode
    lsp-mode
    typescript-mode)
  '(:seperate
    company-ispell
    company-files
    company-yasnippet))

;;;;;;
;; Elixir
;;;;;;

;; Configure elixir-lsp
;; replace t with nil to disable.
(setq lsp-elixir-fetch-deps nil)
(setq lsp-elixir-suggest-specs t)
(setq lsp-elixir-signature-after-complete t)
(setq lsp-elixir-enable-test-lenses t)

;; Compile and test on save
(setq alchemist-hooks-test-on-save t)
(setq alchemist-hooks-compile-on-save t)

;; Disable popup quitting for Elixir’s REPL
;; Default behaviour of doom’s treating of Alchemist’s REPL window is to quit the
;; REPL when ESC or q is pressed (in normal mode). It’s quite annoying so below
;; code disables this and set’s the size of REPL’s window to 30% of editor frame’s
;; height.
(set-popup-rule! "^\\*Alchemist-IEx" :quit nil :size 0.3)

;; Do not select exunit-compilation window
(setq shackle-rules '(("*exunit-compilation*" :noselect t))
      shackle-default-rule '(:select t))

(setq lsp-file-watch-ignored '(".idea" "node_modules" ".git" "build" "_build" "deps"))

(setq lsp-elixir-enable-test-lenses t)

;; Set global LSP options
(after! lsp-mode (
                  setq lsp-lens-enable t
                  lsp-ui-peek-enable t
                  lsp-ui-doc-enable nil
                  lsp-ui-doc-position 'bottom
                  lsp-ui-doc-max-height 70
                  lsp-ui-doc-max-width 150
                  lsp-ui-sideline-show-diagnostics t
                  lsp-ui-sideline-show-hover nil
                  lsp-ui-sideline-show-code-actions t
                  lsp-ui-sideline-diagnostic-max-lines 20
                  lsp-ui-sideline-ignore-duplicate t
                  lsp-ui-sideline-enable t))

(after! lsp-mode
  (dolist (match
           '("[/\\\\]_build\\'"
             "[/\\\\]deps\\'"))
    (add-to-list 'lsp-file-watch-ignored-directories match)))

(setq native-comp-driver-options (when (eq system-type 'darwin) '("-Wl,-w")))
