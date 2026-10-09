####################################################################################################
#                                         CONFIGURATION                                            #
####################################################################################################
#
# Parametres du jeu. Toutes les dimensions sont exprimees en "units" (cases de la grille d'affichage).
# Modifier ces valeurs suffit a changer l'equilibrage du jeu, aucun autre fichier n'est a toucher.
#
# Reglages du Bitmap Display de RARS a utiliser (la grille obtenue fait 32 x 32 units) :
#	Unit Width in Pixels : 16
#	Unit Height in Pixels : 16
#	Display Width in Pixels : 512
#	Display Height in Pixels : 512
#	Base address for display : 0x10040000 (heap)

.data

#Affichage
I_largeur_ecran : .word 512 #Largeur de l'ecran en pixels
I_hauteur_ecran : .word 512 #Hauteur de l'ecran en pixels
I_largeur_unit : .word 16 #Largeur d'un unit en pixels
I_hauteur_unit : .word 16 #Hauteur d'un unit en pixels

#Partie
frame_delay : .word 40 #Duree d'une frame en millisecondes
invaders_points : .word 10 #Points gagnes pour chaque envahisseur detruit
sound_enabled : .word 1 #1 pour activer les effets sonores, 0 pour les desactiver

#Joueur
player_x_position : .word 13 #Position initiale gauche du joueur en abscisse
player_height : .word 2 #Hauteur du joueur
player_width : .word 5 #Largeur du joueur
player_lives : .word 3 #Nombre de vies du joueur
player_shot_cooldown : .word 6 #Nombre de frames minimum entre deux tirs du joueur
player_color : .word 0x0033ccff #Couleur du joueur (et de l'indicateur de vies)

#Envahisseurs
invaders_number : .word 18 #Nombre d'envahisseurs
invaders_per_ligne : .word 6 #Nombre d'envahisseurs par ligne
invaders_height : .word 2 #Hauteur d'un envahisseur
invaders_width : .word 3 #Largeur d'un envahisseur
invaders_x_movement : .word 1 #Mouvement horizontal des envahisseurs a chaque deplacement
invaders_y_movement : .word 1 #Mouvement vertical des envahisseurs quand ils atteignent un bord
invaders_x_margin : .word 1 #Marge horizontale
invaders_y_margin : .word 2 #Marge verticale
invaders_x_spacing : .word 1 #Espace horizontal entre les envahisseurs
invaders_y_spacing : .word 1 #Espace vertical entre les envahisseurs
invaders_min_period : .word 2 #Nombre minimum de frames entre deux deplacements des envahisseurs
invaders_speed_divisor : .word 3 #Periode de deplacement = min_period + envahisseurs_en_vie / speed_divisor
invaders_shot_period : .word 16 #Nombre de frames entre deux tirs des envahisseurs
invaders_color : .word 0x0066ff33 #Couleur des envahisseurs

#Murs
walls_x_margin : .word 2 #Marge avant le debut des murs
walls_number : .word 4 #Nombre de murs
walls_x_spacing : .word 4 #Espacement des murs
walls_height : .word 2 #Hauteur des murs
walls_width : .word 4 #Largeur des murs
walls_resistance : .word 4 #Nombre d'impacts qu'un mur peut encaisser avant de disparaitre
walls_color : .word 0x00ffaa00 #Couleur des murs intacts
walls_damaged_color : .word 0x00994400 #Couleur des murs a moitie detruits
walls_y_position : .word 0 #Ordonnee haute des murs, calculee par O_creer (4/5 de la hauteur)

#Missiles
missiles_height : .word 2 #Hauteur des missiles
missiles_width : .word 1 #Largeur des missiles
missiles_speed : .word 1 #Deplacement des missiles par frame
missiles_maximum : .word 12 #Nombre maximum de missiles sur le terrain
missiles_up_color : .word 0x00ffffff #Couleur des missiles du joueur
missiles_down_color : .word 0x00ff3355 #Couleur des missiles des envahisseurs

#Clavier (Keyboard and Display MMIO Simulator)
keyboard_status_address : .word 0xffff0000 #Adresse du registre de statut du clavier (RCR)
keyboard_data_address : .word 0xffff0004 #Adresse du registre de donnee du clavier (RDR)
key_left : .word 105 #Valeur ascii de i : deplacement a gauche
key_shoot : .word 111 #Valeur ascii de o : tir
key_right : .word 112 #Valeur ascii de p : deplacement a droite
key_quit : .word 120 #Valeur ascii de x : quitter la partie

#Les valeurs associees aux directions des envahisseurs
invaders_direction_right : .word 0
invaders_direction_left : .word 1

#Les valeurs associees aux statuts vitaux des envahisseurs
invaders_dead_status : .word 0
invaders_alive_status : .word 1

#Les valeurs associees aux directions des missiles
missiles_direction_down : .word 0
missiles_direction_up : .word 1

#Les valeurs associees aux etats d'existence des missiles
missiles_not_exist_status : .word 0
missiles_exist_status : .word 1

#Les valeurs renvoyees par P_frame
game_running_status : .word 0
game_victory_status : .word 1
game_defeat_status : .word 2
game_quit_status : .word 3
