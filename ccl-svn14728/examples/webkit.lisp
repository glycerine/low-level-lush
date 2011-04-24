
;;;-*-Mode: LISP; Package: CCL -*-

(in-package "CCL")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "COCOA"))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (objc:load-framework "WebKit" :webkit))


(defun pathname-to-file-url (pathname)
  ;; NATIVE-TRANSLATED-NAMESTRING returns a simple string that can be
  ;; passed to a filesystem function.  (It may be exactly the same as
  ;; what NAMESTRING returns, or it may differ if special characters
  ;; were escaped in NAMESTRING's result.)
  (with-autorelease-pool
    (#/retain
     (#/fileURLWithPath: ns:ns-url (%make-nsstring
                                    (native-translated-namestring pathname))))))

(defun url-from-string (s)
  (with-autorelease-pool
    (#/retain (#/URLWithString: ns:ns-url (%make-nsstring (string s))))))
		  

(defun %browser-window (urlspec)
  (gui::assume-cocoa-thread)
  ;; Content rect for window, bounds rect for view.
  (ns:with-ns-rect (r 100.0 100.0 800.0 600.0)
    (with-autorelease-pool 
      (let* ((url (if (typep urlspec 'pathname)
                    (pathname-to-file-url urlspec)
                    (url-from-string urlspec)))
             ;; Create a window with titlebar, close & iconize buttons
             (w (make-instance
                 'ns:ns-window
                 :with-content-rect r
                 :style-mask (logior #$NSTitledWindowMask
                                     #$NSClosableWindowMask
                                     #$NSMiniaturizableWindowMask
                                     #$NSResizableWindowMask)
                 ;; Backing styles other than #$NSBackingStoreBuffered
                 ;; don't work at all in Cocoa.
                 :backing #$NSBackingStoreBuffered
                 :defer t)))
        (#/setTitle: w (#/absoluteString url))
        ;; Create a web-view instance,
        (let* ((v (make-instance
                   'ns:web-view
                   :with-frame r
                   :frame-name #@"frame" ; could be documented a bit better ...
                   :group-name #@"group"))) ; as could this
          ;; Make the view be the window's content view.
          (#/setContentView: w v)
          ;; Start a URL request.  The request is processed
          ;; asynchronously, but apparently needs to be initiated
          ;; from the event-handling thread.
          (let* ((webframe (#/mainFrame v))
                 (request (#/requestWithURL: ns:ns-url-request url)))
            ;; Failing to wait until the main thread has
            ;; initiated the request seems to cause
            ;; view-locking errors.  Maybe that's just
            ;; an artifact of some other problem.
            (#/loadRequest: webframe request)
            ;; Make the window visible & activate it
            ;; The view knows how to draw itself and respond
            ;; to events.
            (#/makeKeyAndOrderFront: w +null-ptr+))
          v)))))

(defun browser-window (urlspec)
  (let* ((ip ccl::*initial-process*))
    (if (eq ccl::*current-process* ip)
      (%browser-window urlspec)
      (let* ((s (make-semaphore))
             (v nil))
        (process-interrupt ip (lambda ()
                                (setq v (%browser-window urlspec))
                                (signal-semaphore s)))
        (wait-on-semaphore s)
        v))))

	
;;; (browser-window "http://openmcl.clozure.com")
