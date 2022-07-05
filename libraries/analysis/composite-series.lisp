;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(in-package :analysis)

(defclass sequence-model ()
  ((record :accessor record :initform (make-hash-table :test #'equal))))

(defmethod add-record ((model sequence-model) sequence)
  (print "record added"))
