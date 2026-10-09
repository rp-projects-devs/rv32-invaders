####################################################################################################
#                                MOUVEMENT (prefixes J_, M_, E_)                                   #
####################################################################################################
#
# Deplacement du joueur (clavier), des missiles et des envahisseurs, et creation des tirs.
#
# Le clavier est lu via le Keyboard and Display MMIO Simulator de RARS : le registre de statut vaut 1
# lorsqu'une touche a ete pressee, et le registre de donnee contient alors son code ascii.
#
# Depend de : config.s, affichage.s, donnees.s, son.s

.data

M_rng_id : .word 1 #Identifiant du generateur pseudo-aleatoire de RARS, initialise par P_initialiser

.text

#Resume :
#	Lit le clavier et applique l'action correspondante au joueur : deplacement, tir ou abandon.
#	Gere aussi le temps de recharge entre deux tirs.
#Preconditions : Les structures joueur et missiles existent
#Entrees :
#	a0 : Adresse de la structure joueur
#	a1 : Adresse de la structure missiles
#Sorties :
#	a0 : 1 si le joueur demande a quitter la partie, 0 sinon
J_deplacer :
	#Prologue
	addi sp,sp,-16
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse de la structure joueur
	mv s1,a1 #s1 : Adresse de la structure missiles
	lw t0,8(s0) #t0 : Recharge du joueur
	blez t0,J_deplacer_lecture #Si le joueur peut deja tirer, rien a decompter
	addi t0,t0,-1 #t0 : Decremente la recharge
	sw t0,8(s0) #Stocke la nouvelle recharge
	J_deplacer_lecture :
		lw t0,keyboard_status_address
		lw t0,0(t0) #t0 : Statut du clavier
		li t1,1
		bne t0,t1,J_deplacer_rien #Si aucune touche n'a ete pressee, fin de la fonction
		lw t0,keyboard_data_address
		lw s2,0(t0) #s2 : Code ascii de la touche pressee
		lw t0,key_left
		beq s2,t0,J_deplacer_gauche #Si la touche est celle de gauche, deplace le joueur a gauche
		lw t0,key_right
		beq s2,t0,J_deplacer_droite #Si la touche est celle de droite, deplace le joueur a droite
		lw t0,key_shoot
		beq s2,t0,J_deplacer_tir #Si la touche est celle de tir, tente de tirer
		lw t0,key_quit
		beq s2,t0,J_deplacer_quitter #Si la touche est celle d'abandon, demande la fin de la partie
		j J_deplacer_rien #Sinon, la touche est ignoree
	J_deplacer_gauche :
		lw t0,0(s0) #t0 : Abscisse du joueur
		blez t0,J_deplacer_rien #Si le joueur est contre le bord gauche, pas de deplacement
		addi t0,t0,-1 #t0 : Decale le joueur vers la gauche
		sw t0,0(s0) #Stocke la nouvelle abscisse
		j J_deplacer_rien
	J_deplacer_droite :
		lw t0,0(s0) #t0 : Abscisse du joueur
		lw t1,I_largeur #t1 : Largeur de l'image
		lw t2,player_width #t2 : Largeur du joueur
		sub t1,t1,t2 #t1 : Abscisse maximale du joueur
		bge t0,t1,J_deplacer_rien #Si le joueur est contre le bord droit, pas de deplacement
		addi t0,t0,1 #t0 : Decale le joueur vers la droite
		sw t0,0(s0) #Stocke la nouvelle abscisse
		j J_deplacer_rien
	J_deplacer_tir :
		lw t0,8(s0) #t0 : Recharge du joueur
		bgtz t0,J_deplacer_rien #Si l'arme n'est pas rechargee, pas de tir
		mv a0,s1 #a0 : Adresse de la structure missiles
		mv a1,s0 #a1 : Adresse de la structure joueur
		jal M_envoi_missile
		beqz a0,J_deplacer_rien #Si aucun emplacement de missile n'etait libre, pas de recharge
		lw t0,player_shot_cooldown
		sw t0,8(s0) #Lance la recharge
		jal S_tir
		j J_deplacer_rien
	J_deplacer_quitter :
		li a0,1
		j J_deplacer_fin
	J_deplacer_rien :
		li a0,0
	#Epilogue
	J_deplacer_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		addi sp,sp,16
		jr ra
	#Fin epilogue

#Resume :
#	Fait avancer tous les missiles d'un pas et supprime ceux qui sortent de l'ecran
#Preconditions : La structure missiles existe
#Entrees :
#	a0 : Adresse de la structure missiles
#Sorties : //
M_deplacer :
	#Prologue
	addi sp,sp,-36
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	sw s3,16(sp)
	sw s4,20(sp)
	sw s5,24(sp)
	sw s6,28(sp)
	sw s7,32(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse du missile courant
	lw s1,missiles_maximum #s1 : Compteur de missiles
	lw s2,missiles_exist_status #s2 : Statut d'un missile present sur le terrain
	lw s3,missiles_direction_up #s3 : Direction d'un missile qui monte
	lw s4,missiles_speed #s4 : Deplacement d'un missile par frame
	lw s5,I_hauteur #s5 : Hauteur de l'image
	lw s6,missiles_height #s6 : Hauteur d'un missile
	sub s5,s5,s6 #s5 : Ordonnee maximale d'un missile
	M_deplacer_boucle :
		beqz s1,M_deplacer_fin #Si tous les missiles sont traites, fin de la fonction
		lw t0,12(s0) #t0 : Statut d'existence du missile
		bne t0,s2,M_deplacer_suivant #Si le missile n'existe pas, passe au suivant
		lw s7,4(s0) #s7 : Ordonnee du missile
		lw t0,8(s0) #t0 : Direction du missile
		beq t0,s3,M_deplacer_haut #Separation des cas : vers le haut ou vers le bas
		#Missile vers le bas
		add s7,s7,s4 #s7 : Ordonnee + deplacement
		bgt s7,s5,M_deplacer_supprimer #Si le missile sort par le bas, le supprime
		j M_deplacer_sauvegarder
	M_deplacer_haut :
		sub s7,s7,s4 #s7 : Ordonnee - deplacement
		bltz s7,M_deplacer_supprimer #Si le missile sort par le haut, le supprime
	M_deplacer_sauvegarder :
		sw s7,4(s0) #Stocke la nouvelle ordonnee
		j M_deplacer_suivant
	M_deplacer_supprimer :
		lw t0,missiles_not_exist_status
		sw t0,12(s0) #Le missile disparait
	M_deplacer_suivant :
		addi s0,s0,16 #s0 : Missile suivant
		addi s1,s1,-1 #s1 : Decremente le compteur de missiles
		j M_deplacer_boucle
	#Epilogue
	M_deplacer_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		lw s3,16(sp)
		lw s4,20(sp)
		lw s5,24(sp)
		lw s6,28(sp)
		lw s7,32(sp)
		addi sp,sp,36
		jr ra
	#Fin epilogue

#Resume :
#	Cree un missile qui part du milieu du joueur vers le haut
#Preconditions : Les structures missiles et joueur existent
#Entrees :
#	a0 : Adresse de la structure missiles
#	a1 : Adresse de la structure joueur
#Sorties :
#	a0 : 1 si le missile a ete cree, 0 si tous les emplacements sont occupes
M_envoi_missile :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	lw t0,0(a1) #t0 : Abscisse du joueur
	lw t1,player_width
	srli t1,t1,1 #t1 : Largeur du joueur / 2
	add t0,t0,t1 #t0 : Abscisse du milieu du joueur
	lw t1,I_hauteur #t1 : Hauteur de l'image
	lw t2,player_height
	sub t1,t1,t2 #t1 : Ordonnee haute du joueur
	lw t2,missiles_height
	sub a2,t1,t2 #a2 : Ordonnee du missile, juste au-dessus du joueur
	mv a1,t0 #a1 : Abscisse du missile
	lw a3,missiles_direction_up #a3 : Le missile monte
	jal M_ajouter_missile
	#Epilogue
	lw ra,0(sp)
	addi sp,sp,4
	jr ra
	#Fin epilogue

#Resume :
#	Choisit un envahisseur vivant au hasard et lui fait tirer un missile vers le bas
#Preconditions : Les structures missiles et envahisseurs existent
#Entrees :
#	a0 : Adresse de la structure missiles
#	a1 : Adresse de la structure envahisseurs
#Sorties : //
M_envoi_invaders :
	#Prologue
	addi sp,sp,-24
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	sw s3,16(sp)
	sw s4,20(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse de la structure missiles
	mv s4,a1 #s4 : Adresse de la structure envahisseurs
	addi s1,a1,8 #s1 : Adresse de l'envahisseur courant
	lw t0,4(a1) #t0 : Nombre d'envahisseurs en vie
	blez t0,M_envoi_invaders_fin #S'il ne reste aucun envahisseur, personne ne tire
	lw a0,M_rng_id #a0 : Identifiant du generateur
	mv a1,t0 #a1 : Borne superieure exclue
	li a7,42
	ecall #a0 : Entier aleatoire dans [0, envahisseurs en vie[
	mv s2,a0 #s2 : Rang du tireur parmi les envahisseurs vivants
	lw s3,invaders_alive_status #s3 : Statut d'un envahisseur vivant
	M_envoi_invaders_recherche :
		lw t0,8(s1) #t0 : Statut vital de l'envahisseur courant
		bne t0,s3,M_envoi_invaders_suivant #Si l'envahisseur est mort, il n'est pas compte
		beqz s2,M_envoi_invaders_tir #Si c'est le vivant recherche, il tire
		addi s2,s2,-1 #s2 : Un vivant de moins a passer
	M_envoi_invaders_suivant :
		addi s1,s1,12 #s1 : Envahisseur suivant
		j M_envoi_invaders_recherche
	M_envoi_invaders_tir :
		#Le tir part de l'envahisseur vivant le plus bas de la colonne du tireur, pour ne pas
		#traverser ses voisins du dessous
		lw t2,0(s1) #t2 : Abscisse de la colonne du tireur
		addi t3,s4,8 #t3 : Adresse de l'envahisseur courant
		lw t4,invaders_number #t4 : Compteur d'envahisseurs
		M_envoi_invaders_colonne :
			beqz t4,M_envoi_invaders_creation #Si tous les envahisseurs sont traites, le tireur est connu
			lw t0,8(t3) #t0 : Statut vital de l'envahisseur
			bne t0,s3,M_envoi_invaders_colonne_suivant #Si l'envahisseur est mort, il ne tire pas
			lw t0,0(t3) #t0 : Abscisse de l'envahisseur
			bne t0,t2,M_envoi_invaders_colonne_suivant #S'il n'est pas dans la colonne, on passe
			lw t0,4(t3) #t0 : Ordonnee de l'envahisseur
			lw t1,4(s1) #t1 : Ordonnee du tireur actuel
			ble t0,t1,M_envoi_invaders_colonne_suivant #S'il n'est pas plus bas, on garde le tireur
			mv s1,t3 #s1 : Nouveau tireur
		M_envoi_invaders_colonne_suivant :
			addi t3,t3,12 #t3 : Envahisseur suivant
			addi t4,t4,-1 #t4 : Decremente le compteur d'envahisseurs
			j M_envoi_invaders_colonne
	M_envoi_invaders_creation :
		lw t0,0(s1) #t0 : Abscisse de l'envahisseur
		lw t1,invaders_width
		srli t1,t1,1 #t1 : Largeur de l'envahisseur / 2
		add a1,t0,t1 #a1 : Abscisse du missile, au milieu de l'envahisseur
		lw t0,4(s1) #t0 : Ordonnee de l'envahisseur
		lw t1,invaders_height
		add a2,t0,t1 #a2 : Ordonnee du missile, juste sous l'envahisseur
		mv a0,s0 #a0 : Adresse de la structure missiles
		lw a3,missiles_direction_down #a3 : Le missile descend
		jal M_ajouter_missile
	#Epilogue
	M_envoi_invaders_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		lw s3,16(sp)
		lw s4,20(sp)
		addi sp,sp,24
		jr ra
	#Fin epilogue

#Resume :
#	Deplace le groupe d'envahisseurs d'un pas horizontal. Si le groupe atteint un bord, il descend
#	d'une ligne et change de direction. Les bords sont calcules a partir des envahisseurs encore
#	vivants : le groupe va donc plus loin quand ses colonnes exterieures sont detruites.
#Preconditions : La structure envahisseurs existe et O_creer a ete appele (walls_y_position connu)
#Entrees :
#	a0 : Adresse de la structure envahisseurs
#Sorties :
#	a0 : 1 si les envahisseurs ont atteint la ligne des murs (defaite), 0 sinon
E_deplacer :
	#Prologue
	addi sp,sp,-32
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	sw s3,16(sp)
	sw s4,20(sp)
	sw s5,24(sp)
	sw s6,28(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse de la structure envahisseurs
	#Calcul des limites du groupe d'envahisseurs vivants
	addi t0,s0,8 #t0 : Adresse de l'envahisseur courant
	lw t1,invaders_number #t1 : Compteur d'envahisseurs
	lw t2,invaders_alive_status #t2 : Statut d'un envahisseur vivant
	lw t3,invaders_width #t3 : Largeur d'un envahisseur
	lw t4,invaders_height #t4 : Hauteur d'un envahisseur
	lw s1,I_largeur #s1 : Abscisse gauche minimale, initialisee au maximum possible
	li s2,0 #s2 : Abscisse droite maximale (exclue)
	li s3,0 #s3 : Ordonnee basse maximale (exclue)
	E_deplacer_limites :
		beqz t1,E_deplacer_limites_fin #Si tous les envahisseurs sont traites, les limites sont connues
		lw t5,8(t0) #t5 : Statut vital de l'envahisseur
		bne t5,t2,E_deplacer_limites_suivant #Si l'envahisseur est mort, il ne compte pas
		lw t5,0(t0) #t5 : Abscisse gauche de l'envahisseur
		bge t5,s1,E_deplacer_limite_droite #Si elle n'est pas plus a gauche que la limite, on la garde
		mv s1,t5 #s1 : Nouvelle abscisse gauche minimale
		E_deplacer_limite_droite :
			add t5,t5,t3 #t5 : Abscisse droite de l'envahisseur
			ble t5,s2,E_deplacer_limite_basse #Si elle n'est pas plus a droite que la limite, on la garde
			mv s2,t5 #s2 : Nouvelle abscisse droite maximale
		E_deplacer_limite_basse :
			lw t5,4(t0) #t5 : Ordonnee haute de l'envahisseur
			add t5,t5,t4 #t5 : Ordonnee basse de l'envahisseur
			ble t5,s3,E_deplacer_limites_suivant #Si elle n'est pas plus basse que la limite, on la garde
			mv s3,t5 #s3 : Nouvelle ordonnee basse maximale
	E_deplacer_limites_suivant :
		addi t0,t0,12 #t0 : Envahisseur suivant
		addi t1,t1,-1 #t1 : Decremente le compteur d'envahisseurs
		j E_deplacer_limites
	E_deplacer_limites_fin :
		lw t0,4(s0) #t0 : Nombre d'envahisseurs en vie
		blez t0,E_deplacer_rien #S'il n'y a plus d'envahisseurs, rien a deplacer
		lw t0,walls_y_position #t0 : Ordonnee des murs
		bge s3,t0,E_deplacer_invasion #Si les envahisseurs atteignent les murs, c'est perdu
	#Deplacement horizontal ou descente
	lw s4,invaders_x_movement #s4 : Deplacement horizontal
	lw s5,invaders_x_margin #s5 : Marge horizontale
	lw t0,0(s0) #t0 : Direction du groupe
	lw t1,invaders_direction_right
	bne t0,t1,E_deplacer_vers_gauche #Separation des cas : vers la droite ou vers la gauche
	#Vers la droite
	add t0,s2,s4 #t0 : Abscisse droite apres deplacement
	lw t1,I_largeur
	sub t1,t1,s5 #t1 : Limite droite autorisee
	bgt t0,t1,E_deplacer_demi_tour_gauche #Si le groupe depasserait le bord droit, demi-tour
	mv a1,s4 #a1 : Decalage positif
	j E_deplacer_horizontal
	E_deplacer_demi_tour_gauche :
		mv a0,s0
		jal E_deplacer_bas
		lw t0,invaders_direction_left
		sw t0,0(s0) #Le groupe part maintenant vers la gauche
		j E_deplacer_rien
	E_deplacer_vers_gauche :
		sub t0,s1,s4 #t0 : Abscisse gauche apres deplacement
		blt t0,s5,E_deplacer_demi_tour_droite #Si le groupe depasserait le bord gauche, demi-tour
		neg a1,s4 #a1 : Decalage negatif
		j E_deplacer_horizontal
	E_deplacer_demi_tour_droite :
		mv a0,s0
		jal E_deplacer_bas
		lw t0,invaders_direction_right
		sw t0,0(s0) #Le groupe part maintenant vers la droite
		j E_deplacer_rien
	E_deplacer_horizontal :
		addi s6,s0,8 #s6 : Adresse de l'envahisseur courant
		lw t1,invaders_number #t1 : Compteur d'envahisseurs
		E_deplacer_horizontal_boucle :
			beqz t1,E_deplacer_rien #Si tous les envahisseurs sont decales, fin du deplacement
			lw t0,0(s6) #t0 : Abscisse de l'envahisseur
			add t0,t0,a1 #t0 : Abscisse decalee
			sw t0,0(s6) #Stocke la nouvelle abscisse
			addi s6,s6,12 #s6 : Envahisseur suivant
			addi t1,t1,-1 #t1 : Decremente le compteur d'envahisseurs
			j E_deplacer_horizontal_boucle
	E_deplacer_invasion :
		li a0,1
		j E_deplacer_fin
	E_deplacer_rien :
		li a0,0
	#Epilogue
	E_deplacer_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		lw s3,16(sp)
		lw s4,20(sp)
		lw s5,24(sp)
		lw s6,28(sp)
		addi sp,sp,32
		jr ra
	#Fin epilogue

#Resume :
#	Fait descendre tous les envahisseurs d'un pas vertical
#Preconditions : La structure envahisseurs existe
#Entrees :
#	a0 : Adresse de la structure envahisseurs
#Sorties : //
E_deplacer_bas :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	addi t0,a0,8 #t0 : Adresse de l'envahisseur courant
	lw t1,invaders_number #t1 : Compteur d'envahisseurs
	lw t2,invaders_y_movement #t2 : Deplacement vertical
	E_deplacer_bas_boucle :
		beqz t1,E_deplacer_bas_fin #Si tous les envahisseurs sont descendus, fin de la fonction
		lw t3,4(t0) #t3 : Ordonnee de l'envahisseur
		add t3,t3,t2 #t3 : Ordonnee + deplacement vertical
		sw t3,4(t0) #Stocke la nouvelle ordonnee
		addi t0,t0,12 #t0 : Envahisseur suivant
		addi t1,t1,-1 #t1 : Decremente le compteur d'envahisseurs
		j E_deplacer_bas_boucle
	#Epilogue
	E_deplacer_bas_fin :
		lw ra,0(sp)
		addi sp,sp,4
		jr ra
	#Fin epilogue
