####################################################################################################
#                           GESTION DES DONNEES (prefixes J_, E_, O_, M_)                          #
####################################################################################################
#
# Creation des structures du jeu dans le tas et dessin de ces structures dans le buffer.
#
# Disposition des structures en memoire (1 mot = 4 octets) :
#
# Joueur (J_), 3 mots :
#	+0 : Position horizontale (abscisse gauche)
#	+4 : Nombre de vies
#	+8 : Recharge, nombre de frames restantes avant de pouvoir tirer de nouveau
#
# Envahisseurs (E_), 2 mots + N x 3 mots avec N = invaders_number :
#	+0 : Direction du groupe
#	+4 : Nombre d'envahisseurs en vie
#	+8 : Envahisseurs, chacun sur 3 mots :
#		+0 : Position horizontale
#		+4 : Position verticale
#		+8 : Statut vital
#
# Obstacles (O_), N x 2 mots avec N = walls_number :
#	+0 : Position horizontale
#	+4 : Resistance restante (0 = mur detruit)
#	L'ordonnee, commune a tous les murs, est stockee dans walls_y_position.
#
# Missiles (M_), N x 4 mots avec N = missiles_maximum :
#	+0 : Position horizontale
#	+4 : Position verticale
#	+8 : Direction
#	+12 : Statut d'existence
#
# Depend de : config.s, affichage.s

.text

#Resume :
#	Cree la structure joueur dans le tas
#Preconditions : //
#Entrees : //
#Sorties :
#	a0 : Adresse memoire du debut de la structure joueur
J_creer :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	li a7,9
	li a0,3 #a0 : Nombre de mots de la structure
	slli a0,a0,2 #a0 : Multiplie le nombre de mots par 4 pour obtenir le nombre d'octets
	ecall #Alloue 3x4 octets dans le tas
	lw t0,player_x_position #t0 : Position horizontale initiale du joueur
	sw t0,0(a0) #Stocke la position horizontale du joueur
	lw t0,player_lives #t0 : Nombre de vies initial du joueur
	sw t0,4(a0) #Stocke le nombre de vies du joueur
	sw zero,8(a0) #Le joueur peut tirer des la premiere frame
	#Epilogue
	lw ra,0(sp)
	addi sp,sp,4
	jr ra
	#Fin epilogue

#Resume :
#	Cree la structure envahisseurs dans le tas et place les envahisseurs en grille
#Preconditions : //
#Entrees : //
#Sorties :
#	a0 : Adresse memoire du debut de la structure envahisseurs
E_creer :
	#Prologue
	addi sp,sp,-20
	sw ra,0(sp)
	sw s1,4(sp)
	sw s2,8(sp)
	sw s3,12(sp)
	sw s4,16(sp)
	#Fin prologue
	lw t0,invaders_number #t0 : Nombre d'envahisseurs
	li t1,3
	mul a0,t0,t1 #a0 : 3 mots par envahisseur
	addi a0,a0,2 #a0 : Ajoute le mot de direction et le mot du nombre d'envahisseurs en vie
	slli a0,a0,2 #a0 : Multiplie le nombre de mots par 4 pour obtenir le nombre d'octets
	li a7,9
	ecall #Alloue la structure dans le tas
	mv t1,a0 #t1 : Adresse mouvante dans la structure
	lw t2,invaders_direction_right #t2 : Direction de depart des envahisseurs
	sw t2,0(t1) #Stocke la direction de depart
	sw t0,4(t1) #Stocke le nombre d'envahisseurs en vie
	addi t1,t1,8 #t1 : Adresse du premier envahisseur
	li t2,0 #t2 : Indice de l'envahisseur
	lw t3,invaders_x_margin #t3 : Abscisse du premier envahisseur
	lw t4,invaders_y_margin #t4 : Ordonnee du premier envahisseur
	lw t5,invaders_per_ligne #t5 : Nombre d'envahisseurs par ligne
	lw t6,invaders_alive_status #t6 : Statut d'un envahisseur vivant
	lw s1,invaders_x_spacing #s1 : Espace horizontal entre les envahisseurs
	lw s2,invaders_y_spacing #s2 : Espace vertical entre les envahisseurs
	lw s3,invaders_width #s3 : Largeur des envahisseurs
	lw s4,invaders_height #s4 : Hauteur des envahisseurs
	add s1,s1,s3 #s1 : Distance horizontale entre les coins superieurs gauches de 2 envahisseurs
	add s2,s2,s4 #s2 : Distance verticale entre les coins superieurs gauches de 2 envahisseurs
	li s4,0 #s4 : Indice de la colonne
	E_creer_boucle :
		bge t2,t0,E_creer_fin #Si tous les envahisseurs sont places, fin de la fonction
		sw t3,0(t1) #Stocke la position horizontale de l'envahisseur
		sw t4,4(t1) #Stocke la position verticale de l'envahisseur
		sw t6,8(t1) #Stocke le statut vital de l'envahisseur
		addi t1,t1,12 #t1 : Envahisseur suivant
		addi t2,t2,1 #t2 : Incremente l'indice des envahisseurs
		addi s4,s4,1 #s4 : Incremente l'indice de la colonne
		add t3,t3,s1 #t3 : Abscisse de l'envahisseur suivant
		bne s4,t5,E_creer_boucle #Si on n'est pas en fin de ligne, continue la ligne
		#Sinon, passe a la ligne suivante
		lw t3,invaders_x_margin #t3 : Retour en debut de ligne
		add t4,t4,s2 #t4 : Ordonnee de la ligne suivante
		li s4,0 #s4 : Reinitialise l'indice de la colonne
		j E_creer_boucle
	#Epilogue
	E_creer_fin :
		lw ra,0(sp)
		lw s1,4(sp)
		lw s2,8(sp)
		lw s3,12(sp)
		lw s4,16(sp)
		addi sp,sp,20
		jr ra
	#Fin epilogue

#Resume :
#	Cree la structure obstacles dans le tas et calcule l'ordonnee des murs (4/5 de la hauteur)
#Preconditions : I_creer a deja ete appele (I_hauteur est connu)
#Entrees : //
#Sorties :
#	a0 : Adresse memoire du debut de la structure obstacles
O_creer :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	lw t0,I_hauteur #t0 : Hauteur de l'image
	li t1,5
	div t0,t0,t1 #t0 : 1/5 de la hauteur
	li t1,4
	mul t0,t0,t1 #t0 : 4/5 de la hauteur
	sw t0,walls_y_position,t1 #Stocke l'ordonnee des murs
	lw t5,walls_number #t5 : Nombre de murs
	slli a0,t5,3 #a0 : 2 mots de 4 octets par mur
	li a7,9
	ecall #Alloue la structure dans le tas
	mv t0,a0 #t0 : Adresse mouvante dans la structure
	li t1,0 #t1 : Indice du mur
	lw t2,walls_x_margin #t2 : Abscisse du premier mur
	lw t3,walls_x_spacing #t3 : Espace horizontal entre 2 murs
	lw t4,walls_width #t4 : Largeur des murs
	add t3,t3,t4 #t3 : Distance entre les coins superieurs gauches de 2 murs
	lw t4,walls_resistance #t4 : Resistance initiale des murs
	O_creer_boucle :
		bge t1,t5,O_creer_fin #Si tous les murs sont places, fin de la fonction
		sw t2,0(t0) #Stocke la position horizontale du mur
		sw t4,4(t0) #Stocke la resistance du mur
		add t2,t2,t3 #t2 : Abscisse du mur suivant
		addi t1,t1,1 #t1 : Incremente l'indice des murs
		addi t0,t0,8 #t0 : Mur suivant
		j O_creer_boucle
	#Epilogue
	O_creer_fin :
		lw ra,0(sp)
		addi sp,sp,4
		jr ra
	#Fin epilogue

#Resume :
#	Cree la structure missiles dans le tas, aucun missile n'est present au depart
#Preconditions : //
#Entrees : //
#Sorties :
#	a0 : Adresse memoire du debut de la structure missiles
M_creer :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	lw a0,missiles_maximum #a0 : Nombre maximum de missiles
	mv t1,a0 #t1 : Compteur de missiles
	slli a0,a0,4 #a0 : 4 mots de 4 octets par missile
	li a7,9
	ecall #Alloue la structure dans le tas
	mv t0,a0 #t0 : Adresse mouvante dans la structure
	lw t2,missiles_not_exist_status #t2 : Statut d'un missile absent du terrain
	M_creer_boucle :
		beqz t1,M_creer_fin #Si tous les missiles sont initialises, fin de la fonction
		sw t2,12(t0) #Le missile n'existe pas encore
		addi t0,t0,16 #t0 : Missile suivant
		addi t1,t1,-1 #t1 : Decremente le compteur de missiles
		j M_creer_boucle
	#Epilogue
	M_creer_fin :
		lw ra,0(sp)
		addi sp,sp,4
		jr ra
	#Fin epilogue

#Resume :
#	Ajoute un missile dans le premier emplacement libre de la structure missiles
#Preconditions : La structure missiles existe
#Entrees :
#	a0 : Adresse de la structure missiles
#	a1 : Position horizontale
#	a2 : Position verticale
#	a3 : Direction
#Sorties :
#	a0 : 1 si le missile a ete ajoute, 0 si tous les emplacements sont occupes
M_ajouter_missile :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	mv t0,a0 #t0 : Adresse du missile teste
	lw t1,missiles_maximum #t1 : Compteur de missiles restant a tester
	lw t3,missiles_not_exist_status #t3 : Statut d'un missile absent du terrain
	lw t4,missiles_exist_status #t4 : Statut d'un missile present sur le terrain
	M_ajouter_missile_boucle :
		beqz t1,M_ajouter_missile_plein #Si aucun emplacement n'est libre, le missile n'est pas ajoute
		lw t5,12(t0) #t5 : Statut d'existence du missile teste
		beq t5,t3,M_ajouter_missile_libre #Si l'emplacement est libre, y place le missile
		addi t0,t0,16 #t0 : Missile suivant
		addi t1,t1,-1 #t1 : Decremente le compteur de missiles
		j M_ajouter_missile_boucle
	M_ajouter_missile_libre :
		sw a1,0(t0) #Stocke la position horizontale du missile
		sw a2,4(t0) #Stocke la position verticale du missile
		sw a3,8(t0) #Stocke la direction du missile
		sw t4,12(t0) #Le missile existe
		li a0,1
		j M_ajouter_missile_fin
	M_ajouter_missile_plein :
		li a0,0
	#Epilogue
	M_ajouter_missile_fin :
		lw ra,0(sp)
		addi sp,sp,4
		jr ra
	#Fin epilogue

#Resume :
#	Dessine le joueur en bas de l'ecran et ses vies restantes en haut a gauche
#Preconditions : La structure joueur et le buffer existent
#Entrees :
#	a0 : Adresse de la structure joueur
#Sorties : //
J_afficher :
	#Prologue
	addi sp,sp,-12
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse de la structure joueur
	lw t1,I_hauteur #t1 : Hauteur de l'image
	lw a3,player_height #a3 : Hauteur du joueur
	sub a1,t1,a3 #a1 : Ordonnee du joueur, colle au bas de l'ecran
	lw a0,0(s0) #a0 : Abscisse du joueur
	lw a2,player_width #a2 : Largeur du joueur
	lw a4,player_color #a4 : Couleur du joueur
	jal I_rectangle #Dessine le joueur
	lw s1,4(s0) #s1 : Compteur de vies a dessiner
	li a0,1 #a0 : Abscisse du premier indicateur de vie
	li a1,0 #a1 : Ordonnee des indicateurs de vie
	li a2,1 #a2 : Largeur d'un indicateur
	li a3,1 #a3 : Hauteur d'un indicateur
	J_afficher_boucle_vies :
		blez s1,J_afficher_fin #Si toutes les vies sont dessinees, fin de la fonction
		jal I_rectangle #Dessine un indicateur de vie
		addi a0,a0,2 #a0 : Abscisse de l'indicateur suivant
		addi s1,s1,-1 #s1 : Decremente le compteur de vies
		j J_afficher_boucle_vies
	#Epilogue
	J_afficher_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		addi sp,sp,12
		jr ra
	#Fin epilogue

#Resume :
#	Dessine les envahisseurs en vie dans le buffer
#Preconditions : La structure envahisseurs et le buffer existent
#Entrees :
#	a0 : Adresse de la structure envahisseurs
#Sorties : //
E_afficher :
	#Prologue
	addi sp,sp,-16
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	#Fin prologue
	addi s0,a0,8 #s0 : Adresse du premier envahisseur
	lw s1,invaders_number #s1 : Compteur d'envahisseurs
	lw s2,invaders_alive_status #s2 : Statut d'un envahisseur vivant
	lw a2,invaders_width #a2 : Largeur des envahisseurs
	lw a3,invaders_height #a3 : Hauteur des envahisseurs
	lw a4,invaders_color #a4 : Couleur des envahisseurs
	E_afficher_boucle :
		beqz s1,E_afficher_fin #Si tous les envahisseurs sont traites, fin de la fonction
		lw t0,8(s0) #t0 : Statut vital de l'envahisseur
		bne t0,s2,E_afficher_suivant #Si l'envahisseur est mort, passe au suivant
		lw a0,0(s0) #a0 : Abscisse de l'envahisseur
		lw a1,4(s0) #a1 : Ordonnee de l'envahisseur
		jal I_rectangle #Dessine l'envahisseur
	E_afficher_suivant :
		addi s0,s0,12 #s0 : Envahisseur suivant
		addi s1,s1,-1 #s1 : Decremente le compteur d'envahisseurs
		j E_afficher_boucle
	#Epilogue
	E_afficher_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		addi sp,sp,16
		jr ra
	#Fin epilogue

#Resume :
#	Dessine les murs encore debout dans le buffer, avec une couleur plus sombre s'ils sont abimes
#Preconditions : La structure obstacles et le buffer existent
#Entrees :
#	a0 : Adresse de la structure obstacles
#Sorties : //
O_afficher :
	#Prologue
	addi sp,sp,-16
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse du premier mur
	lw s1,walls_number #s1 : Compteur de murs
	lw s2,walls_resistance
	srli s2,s2,1 #s2 : Moitie de la resistance initiale, seuil du changement de couleur
	lw a1,walls_y_position #a1 : Ordonnee des murs
	lw a2,walls_width #a2 : Largeur des murs
	lw a3,walls_height #a3 : Hauteur des murs
	O_afficher_boucle :
		beqz s1,O_afficher_fin #Si tous les murs sont traites, fin de la fonction
		lw t0,4(s0) #t0 : Resistance du mur
		blez t0,O_afficher_suivant #Si le mur est detruit, passe au suivant
		lw a4,walls_color #a4 : Couleur d'un mur intact
		bgt t0,s2,O_afficher_dessiner #Si le mur a plus de la moitie de sa resistance, garde cette couleur
		lw a4,walls_damaged_color #a4 : Sinon, couleur d'un mur abime
	O_afficher_dessiner :
		lw a0,0(s0) #a0 : Abscisse du mur
		jal I_rectangle #Dessine le mur
	O_afficher_suivant :
		addi s0,s0,8 #s0 : Mur suivant
		addi s1,s1,-1 #s1 : Decremente le compteur de murs
		j O_afficher_boucle
	#Epilogue
	O_afficher_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		addi sp,sp,16
		jr ra
	#Fin epilogue

#Resume :
#	Dessine les missiles presents sur le terrain, avec une couleur differente selon leur direction
#Preconditions : La structure missiles et le buffer existent
#Entrees :
#	a0 : Adresse de la structure missiles
#Sorties : //
M_afficher :
	#Prologue
	addi sp,sp,-20
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	sw s3,16(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse du premier missile
	lw s1,missiles_maximum #s1 : Compteur de missiles
	lw s2,missiles_exist_status #s2 : Statut d'un missile present sur le terrain
	lw s3,missiles_direction_up #s3 : Direction d'un missile du joueur
	lw a2,missiles_width #a2 : Largeur des missiles
	lw a3,missiles_height #a3 : Hauteur des missiles
	M_afficher_boucle :
		beqz s1,M_afficher_fin #Si tous les missiles sont traites, fin de la fonction
		lw t0,12(s0) #t0 : Statut d'existence du missile
		bne t0,s2,M_afficher_suivant #Si le missile n'existe pas, passe au suivant
		lw a4,missiles_down_color #a4 : Couleur d'un missile des envahisseurs
		lw t0,8(s0) #t0 : Direction du missile
		bne t0,s3,M_afficher_dessiner #Si le missile descend, garde cette couleur
		lw a4,missiles_up_color #a4 : Sinon, couleur d'un missile du joueur
	M_afficher_dessiner :
		lw a0,0(s0) #a0 : Abscisse du missile
		lw a1,4(s0) #a1 : Ordonnee du missile
		jal I_rectangle #Dessine le missile
	M_afficher_suivant :
		addi s0,s0,16 #s0 : Missile suivant
		addi s1,s1,-1 #s1 : Decremente le compteur de missiles
		j M_afficher_boucle
	#Epilogue
	M_afficher_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		lw s3,16(sp)
		addi sp,sp,20
		jr ra
	#Fin epilogue
