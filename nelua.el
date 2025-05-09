;;; nelua.el --- Major mode for editing Nelua files

;; Copyright (C) 2025
;; Author: Dean Hunter
;; Keywords: Nelua

;;; Commentary:
;; This mode provides syntax highlighting for the Nelua programming language,

;;; Code:

(require 'cc-mode)

(defvar nelua-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; - comments
    (modify-syntax-entry ?- ". 12" table)
    (modify-syntax-entry ?\n ">" table)
    
    ;; [[ ]] style comments/strings
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    
    ;; ' and " are string delimiters
    (modify-syntax-entry ?\' "\"" table)
    (modify-syntax-entry ?\" "\"" table)
    
    ;; underscore can be part of a word
    (modify-syntax-entry ?_ "w" table)
    
    table)
  "Syntax table for `nelua-mode'.")

(defvar nelua-font-lock-keywords
  (list
   ;; Keywords
   `(,(concat "\\<"
              (regexp-opt '("and" "break" "do" "else" "elseif" "end" "false" "for" "function"
                            "goto" "if" "in" "local" "global" "nil" "not" "or" "repeat" "return"
                            "then" "true" "until" "while" "switch" "case" "defer" "continue"
                            "require" "import" "as" "overload")
                          t)
              "\\>")
     . font-lock-keyword-face)
   
   ;; Type-related keywords
   `(,(concat "\\<"
              (regexp-opt '("integer" "number" "boolean" "string" "any" "auto"
                            "int8" "int16" "int32" "int64" "uint8" "uint16" "uint32" "uint64"
                            "float32" "float64" "cstring" "pointer" "record" "niltype"
                            "enum" "type" "concept" "trait" "generic" "union") 
                          t)
              "\\>")
     . font-lock-type-face)
   
   ;; Annotations in angle brackets (e.g. <comptime>) – color full token
   '("<[a-zA-Z_][a-zA-Z0-9_]*>" . font-lock-builtin-face)

   ;; Specifically highlight common annotations
   `(,(concat "<"
              (regexp-opt '("comptime" "const" "inline" "noinit" "volatile" "noreturn" "nodecl"
                           "cimport" "callconv" "aligned" "restrict" "thread_local" "atomic"
                           "exportC" "linkname" "fastcall" "stdcall") t)
              ">")
     . font-lock-builtin-face)
   
   ;; C emission directives (highlight within preprocessor blocks)
   '("\\<\\(cinclude\\|cemitdecl\\|cemitdefn\\|cemit\\)\\>" . font-lock-builtin-face)
   
   ;; Preprocessor directives (##) - single line
   '("^\\s-*##.*$" . font-lock-preprocessor-face)
   
   ;; Preprocessor directives function calls
   '("##\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\>" 1 font-lock-function-name-face)
   
   ;; Preprocessor code blocks with varying levels of = in delimiters
   '("##\\(\\[=*\\[\\)\\(?:.\\|\n\\)*?\\(\\]=*\\]\\)" 
     (0 font-lock-preprocessor-face)
     (1 font-lock-comment-delimiter-face)
     (2 font-lock-comment-delimiter-face))
   
   ;; Special case for require in preprocessor blocks
   '("##.*\\<\\(require\\)\\>" 1 font-lock-keyword-face)
   
   ;; Compile-time expression evaluation with #[ ]#
   '("#\\(\\[\\)\\(?:.\\|\n\\)*?\\(\\]\\)#"
     (0 font-lock-preprocessor-face)
     (1 font-lock-comment-delimiter-face)
     (2 font-lock-comment-delimiter-face))
   
   ;; Type annotations with @ symbol
   '("@\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\({[^}]*}\\)?" 
     (1 font-lock-type-face))
   
   ;; Function calls
   '("\\<\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\s-*(" 1 font-lock-function-name-face)
   
   ;; Function declarations
   '("\\<function\\>\\s-+\\(?:local\\|global\\)?\\s-*\\([a-zA-Z_][a-zA-Z0-9_]*\\(?:\\.[a-zA-Z_][a-zA-Z0-9_]*\\)?\\)\\s-*("
     1 font-lock-function-name-face)
   
   ;; Variables
   '("\\<local\\|global\\>\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1 font-lock-variable-name-face)
   
   ;; Comments (single line)
   '("--[^\\[\\=].*$" . font-lock-comment-face)
   
   ;; Multiline comments --[[ ... ]], highlight entire block uniformly
   '("--\\[=*\\[\\(?:.\\|\n\\)*?\\]=*\\]" . font-lock-comment-face)
   
   ;; Type annotations (improved to catch more complex types)
   '(":\\s-*\\([a-zA-Z_][a-zA-Z0-9_]*\\(?:<[^>]*>\\)?\\)" 1 font-lock-type-face)
   '(":\\s-*{\\([^}]*\\)}" 1 font-lock-type-face)
   
   ;; Highlight require statements
   '("\\<require\\>\\s-+\\('[^']*'\\|\"[^\"]*\"\\)" 1 font-lock-string-face)
   
   ;; C emit directives in preprocessor blocks
   '("\\<c\\(?:include\\|emitdecl\\|emitdefn\\|emit\\)\\>\\s-+\\(\\[=*\\[.*\\]=*\\]\\)" 
     1 font-lock-string-face)
   
   ;; Record field definitions
   '("\\<record\\>.*{[^}]*\\<\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\s-*:" 1 font-lock-variable-name-face)
   
   ;; Pointer dereference (* operator)
   '("\\(\\*\\)\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1 font-lock-keyword-face)
   
   ;; Address-of operator (& operator)
   '("\\(&\\)\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1 font-lock-keyword-face)
   
   ;; Built-in functions
   `(,(concat "\\<"
              (regexp-opt '("print" "error" "assert" "pcall" "xpcall" "tostring" "tonumber"
                            "ipairs" "pairs" "type" "collectgarbage" "dofile" "loadfile"
                            "getmetatable" "setmetatable" "rawget" "rawset" "rawequal" "rawlen") 
                          t)
              "\\>")
     . font-lock-builtin-face)
   
   ;; Numeric literals (decimal, hex, binary, floats, scientific)
   '("\\b\\(0[xX][0-9A-Fa-f]+\\|0[bB][01]+\\|[0-9]+\\(?:\\.[0-9]*\\)?\\(?:[eE][+-]?[0-9]+\\)?\\)\\b" . font-lock-constant-face)

   ;; Variadic/ellipsis operator (...)
   '("\\.\\.\\." . font-lock-builtin-face)

   ;; Size operator (#) when used standalone (avoid matching ##)
   '("[^#]\\(#[^#[:space:]]*\\)" 1 font-lock-builtin-face)

   ;; Highlight the @ sigil
   '("@" . font-lock-preprocessor-face)

   ;; Braces '{' and '}' following record/union keywords for clearer blocks
   '("\\<\\(?:record\\|union\\)\\>\\s-*\\({\\)" 1 font-lock-preprocessor-face)
   '("\\<\\(?:record\\|union\\)\\>\\(?:.\\|\n\\)*?\\(}\\)" 1 font-lock-preprocessor-face)

   ;; Pointer operator (*) when used for dereference or type (standalone)
   '("\\*" . font-lock-keyword-face)
   )
  "Font-lock keywords for `nelua-mode'.")

;;;###autoload
(define-derived-mode nelua-mode prog-mode "Nelua"
  "Major mode for editing Nelua files."
  :syntax-table nelua-mode-syntax-table
  
  ;; Comment setup
  (setq-local comment-start "-- ")
  (setq-local comment-start-skip "-- ")
  (setq-local comment-end "")
  
  ;; Indentation (using Lua-like indentation)
  (setq-local indent-line-function 'nelua-indent-line)
  
  ;; Syntax highlighting
  (setq-local font-lock-defaults '(nelua-font-lock-keywords nil nil nil nil)))

(defun nelua-indent-line ()
  "Indent current line as Nelua code."
  (interactive)
  (let ((target-column
         (save-excursion
           (beginning-of-line)
           (if (bobp)
               0
             (let ((indent-amount 0)
                   (case-fold-search nil))
               ;; Check previous line for indentation hints
               (forward-line -1)
               (beginning-of-line)
               (if (looking-at "^[ \t]*\\(if\\|function\\|for\\|while\\|repeat\\|else\\|elseif\\|do\\|then\\|switch\\|record\\)\\>")
                   (setq indent-amount (+ indent-amount 2)))
               
               ;; Check current line for dedentation hints
               (forward-line 1)
               (if (looking-at "^[ \t]*\\(end\\|else\\|elseif\\|until\\|}\\)\\>")
                   (setq indent-amount (- indent-amount 2)))
               
               (+ (current-indentation) indent-amount))))))
    (if (<= (current-column) (current-indentation))
        (indent-line-to target-column)
      (save-excursion (indent-line-to target-column)))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.nelua\\'" . nelua-mode))

(provide 'nelua)
;;; nelua.el ends here
