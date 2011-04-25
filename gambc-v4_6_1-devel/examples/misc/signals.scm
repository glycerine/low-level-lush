; File: "signals.scm", Time-stamp: <2006-10-07 17:44:19 feeley>

; This program shows how UNIX signals can be handled in Scheme.
;
; % gsc signals.scm 
; % gsi signals
; executing kill -USR1
; got-SIGUSR1
; executing kill -USR2
; got-SIGUSR2
; done

(c-declare #<<c-declare-end

#include <signal.h>

void signal_handler (int sig)
{
  switch (sig)
    {
      case SIGUSR1:
        ___EXT(___raise_interrupt) (___INTR_6);
        break;
      case SIGUSR2:
        ___EXT(___raise_interrupt) (___INTR_7);
        break;
    }
}

void install_SIGUSR_handlers ()
{
  signal (SIGUSR1, signal_handler);
  signal (SIGUSR2, signal_handler);
}

c-declare-end
)

(define install-SIGUSR-handlers
  (c-lambda () void "install_SIGUSR_handlers"))

(define (install-handlers)
  (##interrupt-vector-set! 6 (lambda () (pretty-print 'got-SIGUSR1)))
  (##interrupt-vector-set! 7 (lambda () (pretty-print 'got-SIGUSR2)))
  (install-SIGUSR-handlers))

(install-handlers)

(define my-pid (##os-getpid))

(display "executing kill -USR1\n")

(shell-command (string-append "kill -USR1 " (number->string my-pid)))

(display "executing kill -USR2\n")

(shell-command (string-append "kill -USR2 " (number->string my-pid)))

(display "done\n")
