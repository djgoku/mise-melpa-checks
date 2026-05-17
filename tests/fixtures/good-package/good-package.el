;;; good-package.el --- Test fixture: a clean package that passes all checks  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Jonathan Otsuka

;; Author: Jonathan Otsuka <test@example.com>
;; URL: https://github.com/djgoku/mise-melpa-checks
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;;; Commentary:

;; This is a deliberately clean Emacs package used by the mise-melpa-checks
;; integration tests to verify that no false positives are reported on a
;; well-formed package.

;;; Code:

(defun good-package-greet (name)
  "Return a greeting string for NAME."
  (format "Hello, %s!" name))

(provide 'good-package)

;;; good-package.el ends here
