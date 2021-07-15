;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(uiop:define-package :nyxt/dom
  (:use :common-lisp :nyxt)
  (:import-from #:class-star #:define-class)
  (:import-from #:serapeum #:export-always)
  (:documentation "Nyxt-specific DOM classes and functions operating on them."))
(in-package :nyxt/dom)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (trivial-package-local-nicknames:add-package-local-nickname :alex :alexandria)
  (trivial-package-local-nicknames:add-package-local-nickname :sera :serapeum))

;; TODO: Factor out into a library?

(defvar *nyxt-dom-classes* (make-hash-table :test #'equalp)
  "A table associating the HTML tag name (e.g., \"a\") with the corresponding
  nyxt/dom class.")

(defmacro define-element-classes (&body names)
  (loop for name in names
        collect (let* ((class-name (if (listp name) (first name) name))
                       (tag (str:replace-all "-element"  "" (str:downcase (symbol-name class-name))))
                       (additional-superclasses (when (listp name) (rest name))))
                  `(progn
                     (define-class ,class-name (,@(if additional-superclasses
                                                      additional-superclasses
                                                      '(plump:element)))
                       ()
                       (:export-class-name-p t)
                       (:export-accessor-names-p t)
                       (:export-predicate-name-p t)
                       (:accessor-name-transformer (hu.dwim.defclass-star:make-name-transformer name))
                       (:documentation ,(format nil "An autogenerated class for <~a> HTML tag." tag)))
                     (setf (gethash ,tag *nyxt-dom-classes*)
                           (quote ,class-name))))
          into classes
        finally (return `(progn ,@classes))))


(define-element-classes
  ;; All HTML5 tags, including experimental ones. Scraped with:
  ;;
  ;; (format t "~{~a-element~^ ~}"
  ;;         (map 'list #'(lambda (item)
  ;;                        (slot-value (elt (slot-value item 'plump-dom::%children) 0)
  ;;                                    'plump-dom::%text))
  ;;              (clss:select ".item-name" (plump:parse (dex:get "https://htmlreference.io/")))))
  ;; Pseudo-tags:
  text-element (h-element text-element) list-element structure-element semantic-element
  (checkbox-element input-element) (radio-element input-element) (file-chooser-element input-element)
  ;; HTML5 elements:
  (a-element text-element) abbr-element address-element area-element
  (article-element semantic-element) (aside-element semantic-element)
  audio-element (b-element text-element) base-element bdi-element bdo-element
  blockquote-element body-element br-element button-element canvas-element
  caption-element (cite-element text-element) (code-element text-element) col-element
  colgroup-element data-element datalist-element (dd-element list-element)
  (del-element text-element) details-element dfn-element div-element (dl-element list-element)
  (dt-element list-element) em-element embed-element fieldset-element
  (figcaption-element semantic-element) figure-element (footer-element semantic-element)
  form-element (h1-element h-element) (h2-element h-element) (h3-element h-element)
  (h4-element h-element) (h5-element h-element) (h6-element h-element) head-element
  (header-element semantic-element) hr-element html-element (i-element text-element) iframe-element
  img-element input-element ins-element kbd-element label-element legend-element
  (li-element list-element) link-element (main-element semantic-element) map-element
  (mark-element semantic-element) meta-element meter-element (nav-element semantic-element)
  noscript-element object-element (ol-element list-element) optgroup-element
  (option-element text-element) output-element (p-element text-element) param-element
  (pre-element text-element) progress-element q-element rp-element rt-element rtc-element
  ruby-element samp-element script-element (section-element semantic-element) select-element
  small-element source-element (span-element text-element) (strong-element text-element)
  style-element (sub-element text-element) summary-element (sup-element text-element) table-element
  tbody-element td-element textarea-element tfoot-element th-element thead-element
  (time-element semantic-element) title-element tr-element track-element (ul-element list-element)
  var-element video-element
  ;; obsolete elements (from https://www.w3.org/TR/2010/WD-html5-20100304/obsolete.html):
  applet-element acronym-element bgsound-element dir-element frame-element frameset-element
  noframes-element isindex-element (listing-element text-element) (xmp-element text-element)
  nextid-element noembed-element (plaintext-element text-element) (rb-element ruby-element)
  (basefont-element text-element) (big-element text-element) (blink-element text-element)
  (center-element text-element) (font-element text-element) (marquee-element text-element)
  (multicol-element text-element) (nobr-element text-element) (s-element text-element)
  (spacer-element text-element) (strike-element text-element) (tt-element text-element)
  (u-element text-element)
  ;; Experimental elements:
  dialog-element hgroup-element picture-element slot-element template-element
  (wbr-element text-element))

(defmethod name-dom-elements ((node plump:node))
  (alex:when-let* ((tag-p (plump:element-p node))
                   (class (gethash (plump:tag-name node) *nyxt-dom-classes*)))
    (change-class node class))
  (when (plump:nesting-node-p node)
    (loop for child across (plump:children node)
          do (name-dom-elements child)))
  node)

(export-always 'named-html-parse)
(declaim (ftype (function (string) (values (or plump-dom:root null) &optional)) named-parse))
(defun named-html-parse (input)
  "Assign tag classes (e.g., `input-element') to the nodes in the `plump:parse'-d input."
  (name-dom-elements (plump:parse input)))

(define-parenscript get-document-body-json ()
  (defun process-element (element)
    (let ((object (ps:create :name (ps:@ element node-name)))
          (attributes (ps:chain element attributes)))
      (unless (or (ps:undefined attributes)
                  (= 0 (ps:@ attributes length)))
        (setf (ps:@ object :attributes) (ps:create))
        (loop for i from 0 below (ps:@ attributes length)
              do (setf (ps:@ object :attributes (ps:chain attributes (item i) name))
                       (ps:chain attributes (item i) value))))
      (unless (or (ps:undefined (ps:chain element child-nodes))
                  (= 0 (ps:chain element child-nodes length)))
        (setf (ps:chain object :children)
              (loop for child in (ps:chain element child-nodes)
                    collect (process-element child))))
      (when (or (equal (ps:@ element node-name) "#text")
                (equal (ps:@ element node-name) "#comment")
                (equal (ps:@ element node-name) "#cdata-section"))
        (setf (ps:@ object :text) (ps:@ element text-content)))
      object))
  (ps:chain -j-s-o-n (stringify (process-element (nyxt/ps:qs document "html")))))

(export-always 'named-json-parse)
(declaim (ftype (function (string) (values (or plump-dom:root null) &optional)) named-json-parse))
(defun named-json-parse (json)
  "Return a `plump:root' of a DOM-tree produced from the JSON.

JSON should have the format like what `get-document-body-json' produces:
- A nested hierarchy of objects (with only one root object), where
  - Every object has a 'name' (usually a tag name or '#text'/'#comment').
  - Some objects can have 'attributes' (a string->string dictionary).
  - Some objects have a subarray ('children') of objects working by these three
    rules."
  (labels ((json-to-plump (json-alist parent)
             (let ((element
                     (cond
                       ((string-equal (alex:assoc-value json-alist :name) "#text")
                        (plump:make-text-node parent (alex:assoc-value json-alist :text)))
                       ((string-equal (alex:assoc-value json-alist :name) "#cdata-section")
                        (plump:make-cdata parent :text (alex:assoc-value json-alist :text)))
                       ((string-equal (alex:assoc-value json-alist :name) "#comment")
                        (plump:make-comment parent (alex:assoc-value json-alist :text)))
                       (t (plump:make-element parent (str:downcase
                                                      (alex:assoc-value json-alist :name)))))))
               (when (typep element 'plump:nesting-node)
                 (setf (plump:children element)
                       (plump:ensure-child-array
                        (map 'vector (alex:rcurry #'json-to-plump element)
                             (alex:assoc-value json-alist :children)))))
               (when (typep element 'plump:element)
                 (setf (plump:attributes element)
                       (alex:alist-hash-table
                        (mapcar #'(lambda (pair)
                                    (cons (str:downcase (symbol-name (first pair)))
                                          (rest pair)))
                                (alex:assoc-value json-alist :attributes))
                        :test 'equalp
                        :size (length (alex:assoc-value json-alist
                                                        :attributes)))))
               element)))
    (let ((json (json:decode-json-from-string json))
          (root (plump:make-root)))
      (json-to-plump json root)
      (name-dom-elements root))))

(defmethod url :around ((element plump:element))
  (alex:when-let* ((result (call-next-method))
                   (url (nyxt::ensure-url result)))
    (render-url
     (if (valid-url-p result)
         url
         (apply #'quri:copy-uri (url (current-buffer))
                (append (when (quri:uri-scheme url) `(:scheme ,(quri:uri-scheme url)))
                        (when (quri:uri-userinfo url) `(:userinfo ,(quri:uri-userinfo url)))
                        (when (quri:uri-host url) `(:host ,(quri:uri-host url)))
                        (when (quri:uri-port url) `(:port ,(quri:uri-port url)))
                        (when (quri:uri-path url) `(:path ,(quri:uri-path url)))
                        (when (quri:uri-fragment url) `(:fragment ,(quri:uri-fragment url)))))))))

(defmethod url ((element plump:element))
  (when (plump:has-attribute element "href")
    (plump:get-attribute element "href")))

(defmethod url ((img img-element))
  (when (plump:has-attribute img "src")
    (plump:get-attribute img "src")))

;; REVIEW: Export to :nyxt? We are forced to use it with nyxt/dom: prefix.
(export-always 'body)
(defmethod body ((element plump:element))
  (when (plump:children element)
    (plump:text element)))

(defmethod body ((input input-element))
  (alex:when-let ((body (or (plump:get-attribute input "value")
                            (plump:get-attribute input "placeholder"))))
    body))

(defmethod body ((textarea textarea-element))
  (alex:when-let ((body (or (plump:get-attribute textarea "value")
                            (plump:get-attribute textarea "placeholder"))))
    body))

(defmethod body ((details details-element))
  (when (clss:select "summary" details)
    (plump:text (elt (clss:select "summary" details) 0))))

(defmethod body ((select select-element))
  (str:join ", " (map 'list #'plump:text
                      (clss:select "option" select))))

(defmethod body ((img img-element))
  (when (plump:has-attribute img "alt")
    (plump:get-attribute img "alt")))
