;;; bad-package.el --- bad  -*- lexical-binding: t; -*-

;;; Commentary:

;; bad

;;; Code:

(defun bad-package-greet (name)
  (format "Hello, %s!" undefined-symbol-deliberately))

(provide 'bad-package)

;;; bad-package.el ends here
