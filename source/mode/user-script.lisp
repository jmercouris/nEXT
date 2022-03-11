;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(in-package :nyxt/web-mode)

(define-class user-script ()
  ((name :type (maybe string))
   (code :type string)
   (version "")
   (description "")
   (namespace "")
   (requires
    nil
    :type (maybe hash-table))
   (include
    '()
    :type list-of-strings)
   (exclude
    '()
    :type list-of-strings)
   (all-frames-p
    t
    :type boolean
    :documentation "Whether to run on both top-level frame and all the subframes.
If false, runs on the toplevel frame only.")
   (run-at
    :document-end
    :type (member :document-start :document-end :document-idle)
    :documentation "When to run the script.
Possible values:
- :document-start (page started loading).
- :document-end (page loaded, resources aren't).
- :document-idle (page and resources are loaded)."))
  (:export-class-name-p t)
  (:export-accessor-names-p t)
  (:accessor-name-transformer (class*:make-name-transformer name))
  (:documentation "The Nyxt-internal representation of user scripts to bridge with the renderer."))
(define-user-class user-script)

(defun get-script-text (script)
  (etypecase script
    (pathname
     (alex:read-file-into-string script))
    (quri:uri
     (if (quri:uri-file-p script)
         (alex:read-file-into-string (quri:uri-path script))
         (dex:get (quri:render-uri script))))
    (string
     (cond
       ((valid-url-p script)
        (let ((script (quri:uri script)))
          (if (quri:uri-file-p script)
              (alex:read-file-into-string (quri:uri-path script))
              (dex:get (quri:render-uri script)))))
       ((uiop:file-pathname-p script)
        (alex:read-file-into-string script))
       (t script)))))

(defun nyxt:make-greasemonkey-script (greasemonkey-script)
  (sera:and-let* ((code (nyxt/web-mode::get-script-text greasemonkey-script))
                  (start-position (search "// ==UserScript==" code))
                  (end-position (search "// ==/UserScript==" code))
                  (meta (subseq code
                                (+ (1+ (length "// ==UserScript==")) start-position)
                                end-position)))
    (flet ((getprop (prop)
             (alex:when-let* ((regex (str:concat "// @" prop "\\s*(.*)"))
                              (raw-props (ppcre:all-matches-as-strings regex meta)))
               (mapcar (lambda (raw-prop)
                         (multiple-value-bind (start end reg-starts reg-ends)
                             (ppcre:scan regex raw-prop)
                           (declare (ignore end))
                           (when start
                             (subseq raw-prop (elt reg-starts 0) (elt reg-ends 0)))))
                       raw-props))))
      (make-instance 'nyxt/web-mode:user-script
                     :name (or (first (getprop "name")) (alex:required-argument 'name))
                     :version (first (getprop "version"))
                     :description (first (getprop "description"))
                     :namespace (first (getprop "namespace"))
                     :all-frames-p (not (first (getprop "noframes")))
                     :code (format nil "~{~a;~&~}~a"
                                   (mapcar #'nyxt/web-mode::get-script-text (getprop "require"))
                                   code)
                     :include (append (getprop "include") (getprop "match"))
                     :exclude (getprop "exclude")
                     :run-at (str:string-case (first (getprop "run-at"))
                               ("document-start" :document-start)
                               ("document-end" :document-end)
                               ("document-idle" :document-idle)
                               (otherwise :document-end))))))
