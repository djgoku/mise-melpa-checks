;;; batch-init.el --- Ephemeral Emacs setup for mise-melpa-checks tasks  -*- lexical-binding: t; -*-

;; This file is loaded by every check task via `emacs -Q --batch -l batch-init.el'.
;; It is NOT a user init file.  Its responsibilities:
;;
;;   1. Point `package-user-dir' at a shared cache under $MISE_CACHE_DIR so
;;      package-lint and project deps download once across all projects.
;;   2. Configure GNU ELPA, NonGNU ELPA, and MELPA archives.
;;   3. Refresh archive contents if older than 1 day.
;;   4. Install `package-lint' (idempotent).
;;   5. Parse the project's `Package-Requires:' and install each non-emacs
;;      dependency into the cache, adding it to `load-path'.

;;; Code:

(require 'package)
(require 'lisp-mnt)

(defvar mmc--cache-root
  (or (getenv "MELPA_CHECK_EMACS_DIR")
      (expand-file-name
       "melpa-checks/elpa"
       (or (getenv "MISE_CACHE_DIR")
           (expand-file-name "mise" (or (getenv "XDG_CACHE_HOME")
                                        "~/.cache")))))
  "Shared package-user-dir for all mise-melpa-checks invocations.")

(setq package-user-dir mmc--cache-root)
(make-directory mmc--cache-root t)

(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/")))

(package-initialize)

(defun mmc--archive-stale-p ()
  "Return non-nil if the MELPA archive cache is missing or older than 24h."
  (let* ((file (expand-file-name "archives/melpa/archive-contents"
                                 package-user-dir))
         (mtime (and (file-exists-p file)
                     (file-attribute-modification-time
                      (file-attributes file)))))
    (or (null mtime)
        (> (float-time (time-subtract (current-time) mtime))
           (* 60 60 24)))))

(when (mmc--archive-stale-p)
  (package-refresh-contents))

(defun mmc--ensure (pkg)
  "Install PKG unless already present."
  (unless (package-installed-p pkg)
    (package-install pkg)))

;; package-lint is needed by the package-lint task; cheap to ensure always.
(mmc--ensure 'package-lint)

;; --- Project dep installation ------------------------------------------------

(defun mmc--main-file ()
  "Determine the project's main .el file for Package-Requires parsing.
Order:
  1. $MELPA_CHECK_MAIN env var, if set and the file exists.
  2. <basename-of-default-directory>.el if it exists.
  3. The first .el file (alphabetically) whose first line has a
     `;;; foo.el --- summary' header.
Returns absolute file name, or nil."
  (let* ((cwd (expand-file-name default-directory))
         (env (getenv "MELPA_CHECK_MAIN")))
    (cond
     ((and env (file-exists-p (expand-file-name env cwd)))
      (expand-file-name env cwd))
     ((let* ((base (file-name-nondirectory (directory-file-name cwd)))
             (candidate (expand-file-name (concat base ".el") cwd)))
        (and (file-exists-p candidate) candidate)))
     (t
      ;; Exclude the same files lib/discover-files.sh excludes, plus Emacs
      ;; lockfile symlinks (.#foo.el).  Otherwise flycheck temp buffers and
      ;; lockfiles can be selected as the project's main file.
      (let* ((candidates (seq-remove
                          (lambda (f)
                            (let ((b (file-name-nondirectory f)))
                              (or (string-prefix-p "flycheck_" b)
                                  (string-prefix-p ".#" b)
                                  (string-match-p
                                   "-\\(test\\|tests\\|pkg\\|autoloads\\)\\.el\\'"
                                   b))))
                          (directory-files cwd t "\\.el\\'")))
             (found nil))
        (dolist (f (sort candidates #'string<))
          (when (and (not found)
                     (with-temp-buffer
                       (insert-file-contents f nil 0 200)
                       (goto-char (point-min))
                       (looking-at ";;;[ \t]+[^ \t]+\\.el[ \t]+---")))
            (setq found f)))
        found)))))

(defun mmc--package-requires (file)
  "Return parsed `Package-Requires' from FILE as an alist, or nil."
  (with-temp-buffer
    (insert-file-contents file)
    (let ((raw (lm-header "package-requires")))
      (and raw (car (read-from-string raw))))))

(defun mmc-install-project-deps ()
  "Parse Package-Requires of the project's main file and install non-emacs deps."
  (let ((main (mmc--main-file)))
    (cond
     ((null main)
      (message "mmc: no main .el file detected; skipping dep install"))
     (t
      (message "mmc: parsing Package-Requires from %s"
               (file-relative-name main))
      (dolist (req (mmc--package-requires main))
        (let ((pkg (car req)))
          (unless (eq pkg 'emacs)
            (mmc--ensure pkg))))))))

(mmc-install-project-deps)

(provide 'batch-init)

;;; batch-init.el ends here
