;;; Mail sources

(setq gnus-select-method '(nnml "" (gnus-search-engine gnus-search-find-grep)))

;; This makes pipe deadlocks with nnimap-stream below less likely.
(setq read-process-output-max (* 1024 1024))

(setq gnus-secondary-select-methods
      ;; If this were gnus-select-method, then we'd have
      ;; "gmail.Inbox". This way, we have "nnimap+local:gmail.Inbox".
      '((nnimap "local"
                ;; Use imap-shell-program. We don't have to run a
                ;; dovecot server this way.
                (nnimap-stream shell)
                (nnimap-shell-program
                 "/usr/lib/dovecot/imap -c ~/.dovecot.conf 2>> ~/dovecot.log")
                ;; Trash may be called something else (e.g. Bin).
                ;; Check on Gmail.
                (nnmail-expiry-target "nnimap+local:[Gmail]/Trash")
                (gnus-search-engine gnus-search-imap))))


;;; Getting mail and notifications

;; For ~/bin/mbsync-gmail-full to be able to tell Gnus that new mail
;; may have arrived.
(require 'server)
(unless (server-running-p)
  (server-start))


;;; Summary mode: Threads

(setq gnus-summary-gather-subject-limit 'fuzzy)
(setq gnus-fetch-old-headers t)

;; Thread by subject.
(setq gnus-summary-thread-gathering-function
      'gnus-gather-threads-by-references)

;; Gmail includes mails from Sent Mail in Inbox threads. We can't do
;; that, but pressing "A T" in the summary will fetch them from the
;; same server. For some, we use a batch method, then fall back to
;; search the local server (Dovecot).
(setq gnus-refer-thread-limit 2000)
(setq gnus-refer-thread-use-search t)


;;; Sending mail

(setq gnus-gcc-mark-as-read t)

(require 'smtpmail)

(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      smtpmail-stream-type 'ssl
      smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 465)


;;; Spam filtering

(spam-initialize)

;; Articles in these groups are considered spam (unless marked as
;; ham).
(setq spam-junk-mailgroups '("nnimap+local:gmail.Spam"))
(setq spam-mark-ham-unread-before-move-from-spam-group t)
(setq spam-mark-only-unseen-as-spam nil)
;; Move articles marked as ham out of spam folders to the Inbox.
(setq gnus-ham-process-destinations
      '(("^nnimap\\+local\\:gmail\\.Spam" "nnimap+local:gmail.Inbox")))
;; Move spam to the appropriate (= of the same server) spam folder.
(setq gnus-spam-process-destinations
      '(("^nnimap\\+local\\:gmail\\..*" "nnimap+local:gmail.Spam")))
;; What marks make a ham?
(setq gnus-parameter-ham-marks-alist
      '(("^nnimap\\+local\\:.*\\.Spam%"
         ;; Reading a spam should not mark it as ham, tick it if
         ;; that's wanted.
         ((gnus-ticked-mark)))
        (".*"
         ;; This is the default.
         ((gnus-del-mark gnus-read-mark gnus-killed-mark
                         gnus-kill-file-mark gnus-low-score-mark)))))
