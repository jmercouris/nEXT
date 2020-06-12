(in-package :nyxt)

(define-command about ()
  "Show the list of contributors."
  (let* ((buffer (nyxt/help-mode:help-mode :activate t
                                           :buffer (make-buffer :title "*About*")))
         (contents (markup:markup
                    (:h1 "Contributors")
                    (:p "Let us know if you've contributed to the development of
                    Nyxt and would like to be included on this list.")
                    (:ul
                     (:li "Adom Hartell (@4t0m)")
                     (:li "Solomon Bloch (@noogie13)"))
                    (:h1 "Supporters")
                    (:p "Thank you to NLnet for supporting Nyxt!")
                    (:h1 "Crowdfunding backers")
                    (:p "Thank you to all who have supported and made Nyxt possible!")
                    (:h2 "2018-11 campaign: *NIX Support")
                    (:h3 "Digital Omnipresence")
                    (:ul
                     (:li "Alexander.Shendi")
                     (:li "Ashish SHUKLA")
                     (:li "Christopher Nascone")
                     (:li "dan.girsh")
                     (:li "Eric Monson")
                     (:li "Jack Randall")
                     (:li "James Anderson")
                     (:li "liweitian")
                     (:li "Marco Heisig")
                     (:li "Oluwafemi Agbabiaka")
                     (:li "pjb")
                     (:li "Robert Krahn")
                     (:li "Robert Uhl")
                     (:li "1 anonymous"))
                    (:h3 "Digital Magma")
                    (:ul
                     (:li "Daniel V")
                     (:li "Jason Hamilton")
                     (:li "Magnus Nyberg")
                     (:li "Marek Kochanowicz")
                     (:li "Rich Smith")
                     (:li "Robert Uhl")
                     (:li "simon")
                     (:li "slade")
                     (:li "Steve Last")
                     (:li "ulf.makestad")
                     (:li "1 anonymous"))
                    (:h3 "Digital Immortality")
                    (:ul
                     (:li "Alexey Abramov")
                     (:li "Are Jensen")
                     (:li "Joseph Mingrone")
                     (:li "Nikita Poliakov")
                     (:li "pjb")
                     (:li "Sainath Adapa")
                     (:li "Spencer Heywood")
                     (:li "Sungjin Chun")
                     (:li "Tom Delord")
                     (:li "2 anonymous"))
                    (:h3 "Others")
                    (:ul
                     (:li "Nicholas Zivkovic")
                     (:li "Pierre Neidhardt")
                     (:li "Simon Zugmeyer")
                     (:li "vindarel")
                     (:li "5 anonymous"))
                    (:h2 "2019-10 campaign: v1.4.0")
                    (:h3 "Digital Immortality")
                    (:ul
                     (:li "Tim Johann")
                     (:li "Julien Rousé")
                     (:li "ebababi")
                     (:li "Emil Oppeln-Bronikowski")
                     (:li "Fox Kiester")
                     (:li "Stefan Husmann")
                     (:li "Nils Grunwald")
                     (:li "Florian Adamsky")
                     (:li "Valentin Atanasov")
                     (:li "Pranav Vats")
                     (:li "Jörn Gersdorf")
                     (:li "Matt Skinner")
                     (:li "Jelle Dirk Licht")
                     (:li "Minori Yamashita")
                     (:li "Hugh Daschbach")
                     (:li "Niklas Carlsson")
                     (:li "mestelan")
                     (:li "Camille Troillard")
                     (:li "mace nicolas")
                     (:li "dan.girsh")
                     (:li "Michael Bruderer")
                     (:li "Patrice Rault")
                     (:li "Cees de Groot")
                     (:li "Sam Hedin")
                     (:li "rbarzic")
                     (:li "Jake Waksbaum")
                     (:li "Lukas Jenks")
                     (:li "Rodrigo Lazo")
                     (:li "Lucas Sifoni")
                     (:li "Calle Helmertz")
                     (:li "Kristian Nygaard Jensen")
                     (:li "Robert Uhl")
                     (:li "Francis Burstall")
                     (:li "Arnaud BEAUD'HUIN")
                     (:li "Daniel V")
                     (:li "Albin Heimerson")
                     (:li "Alexander ter Weele")
                     (:li "Jeremy Firth")
                     (:li "aim")
                     (:li "liweitian")
                     (:li "Philipe Dallaire")
                     (:li "Travis Brown")
                     (:li "Divan Santana")
                     (:li "John C Haprian")
                     (:li "Pierrick Maillard")
                     (:li "Dardel Renaud")
                     (:li "Dardel Renaud")
                     (:li "Nils Grunwald")
                     (:li "hector")
                     (:li "Jean Morel")
                     (:li "Jos van Bakel")
                     (:li "slade")
                     (:li "dietrich ayala")
                     (:li "bacon totem")
                     (:li "Pierre Neidhardt")
                     (:li "18 anonymous"))))
         (insert-content (ps:ps (setf (ps:@ document body |innerHTML|)
                                      (ps:lisp contents)))))
    (ffi-buffer-evaluate-javascript buffer insert-content)
    (set-current-buffer buffer)))
