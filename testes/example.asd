(list a 1 2 3 4)

(each a 
      (print (get *)))

(require "math")

(print 
  (trim "     Hi      "))

(print "So, what do you like?")

(set input (trim (read-line)))

(print "Oh, I love " (get input) " too!!")
