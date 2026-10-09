####################################################################################################
#                                   COLLISIONS (prefixes C_, M_)                                   #
####################################################################################################
#
# Detection des impacts de missiles sur les murs, les envahisseurs et le joueur.
# Tous les objets du jeu sont des rectangles alignes sur la grille : un impact est donc un
# chevauchement de deux rectangles (test "AABB", Axis-Aligned Bounding Box).
#
# Depend de : config.s, affichage.s, donnees.s, son.s

.text

#Resume :
#	Verifie si deux rectangles se chevauchent. Deux rectangles se chevauchent si et seulement si
#	chacun commence avant la fin de l'autre, sur les deux axes :
#	x1 < x2 + l2  et  x2 < x1 + l1  et  y1 < y2 + h2  et  y2 < y1 + h1
#Preconditions : Largeurs et hauteurs strictement positives
#Entrees :
#	a0 : Abscisse gauche du rectangle 1
#	a1 : Ordonnee haute du rectangle 1
#	a2 : Largeur du rectangle 1
#	a3 : Hauteur du rectangle 1
#	a4 : Abscisse gauche du rectangle 2
#	a5 : Ordonnee haute du rectangle 2
#	a6 : Largeur du rectangle 2
#	a7 : Hauteur du rectangle 2
#Sorties :
#	a0 : 1 si les rectangles se chevauchent, 0 sinon
C_intersecte_rectangles :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	add t0,a4,a6 #t0 : Abscisse droite du rectangle 2
	bge a0,t0,C_intersecte_rectangles_non #Si le rectangle 1 commence apres la fin du rectangle 2, pas de chevauchement
	add t0,a0,a2 #t0 : Abscisse droite du rectangle 1
	bge a4,t0,C_intersecte_rectangles_non #Si le rectangle 2 commence apres la fin du rectangle 1, pas de chevauchement
	add t0,a5,a7 #t0 : Ordonnee basse du rectangle 2
	bge a1,t0,C_intersecte_rectangles_non #Si le rectangle 1 est sous le rectangle 2, pas de chevauchement
	add t0,a1,a3 #t0 : Ordonnee basse du rectangle 1
	bge a5,t0,C_intersecte_rectangles_non #Si le rectangle 2 est sous le rectangle 1, pas de chevauchement
	li a0,1
	j C_intersecte_rectangles_fin
	C_intersecte_rectangles_non :
		li a0,0
	#Epilogue
	C_intersecte_rectangles_fin :
		lw ra,0(sp)
		addi sp,sp,4
		jr ra
	#Fin epilogue

#Resume :
#	Verifie s'il y a collision entre un missile et un rectangle
#Preconditions : Le missile existe
#Entrees :
#	a0 : Adresse du missile
#	a1 : Abscisse gauche du rectangle
#	a2 : Ordonnee haute du rectangle
#	a3 : Largeur du rectangle
#	a4 : Hauteur du rectangle
#Sorties :
#	a0 : 1 si le missile touche le rectangle, 0 sinon
M_intersecteRectangle :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	mv t0,a0 #t0 : Adresse du missile
	mv a7,a4 #a7 : Hauteur du rectangle
	mv a6,a3 #a6 : Largeur du rectangle
	mv a5,a2 #a5 : Ordonnee du rectangle
	mv a4,a1 #a4 : Abscisse du rectangle
	lw a0,0(t0) #a0 : Abscisse du missile
	lw a1,4(t0) #a1 : Ordonnee du missile
	lw a2,missiles_width #a2 : Largeur du missile
	lw a3,missiles_height #a3 : Hauteur du missile
	jal C_intersecte_rectangles
	#Epilogue
	lw ra,0(sp)
	addi sp,sp,4
	jr ra
	#Fin epilogue

#Resume :
#	Gere tous les impacts de missiles de la frame :
#	- un missile qui touche un mur disparait et abime le mur ;
#	- un missile du joueur qui touche un envahisseur le detruit ;
#	- un missile d'envahisseur qui touche le joueur lui retire une vie.
#Preconditions : Toutes les structures existent
#Entrees :
#	a0 : Adresse de la structure missiles
#	a1 : Adresse de la structure obstacles
#	a2 : Adresse de la structure envahisseurs
#	a3 : Adresse de la structure joueur
#Sorties :
#	a0 : Nombre de points gagnes pendant la frame
#	a1 : 1 si le joueur a ete touche pendant la frame, 0 sinon
C_collision :
	#Prologue
	addi sp,sp,-44
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	sw s3,16(sp)
	sw s4,20(sp)
	sw s5,24(sp)
	sw s6,28(sp)
	sw s7,32(sp)
	sw s8,36(sp)
	sw s9,40(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse du missile courant
	mv s1,a1 #s1 : Adresse de la structure obstacles
	mv s2,a2 #s2 : Adresse de la structure envahisseurs
	mv s3,a3 #s3 : Adresse de la structure joueur
	lw s4,missiles_maximum #s4 : Compteur de missiles
	li s5,0 #s5 : Points gagnes pendant la frame
	li s6,0 #s6 : 1 si le joueur a ete touche
	C_collision_boucle_missiles :
		beqz s4,C_collision_fin #Si tous les missiles sont traites, fin de la fonction
		lw t0,12(s0) #t0 : Statut d'existence du missile
		lw t1,missiles_exist_status
		bne t0,t1,C_collision_missile_suivant #Si le missile n'existe pas, passe au suivant
		#Impacts sur les murs
		mv s7,s1 #s7 : Adresse du mur courant
		lw s8,walls_number #s8 : Compteur de murs
		C_collision_boucle_murs :
			beqz s8,C_collision_cible #Si aucun mur n'est touche, teste la cible du missile
			lw t0,4(s7) #t0 : Resistance du mur
			blez t0,C_collision_mur_suivant #Si le mur est detruit, il n'arrete plus les missiles
			mv a0,s0 #a0 : Adresse du missile
			lw a1,0(s7) #a1 : Abscisse du mur
			lw a2,walls_y_position #a2 : Ordonnee du mur
			lw a3,walls_width #a3 : Largeur du mur
			lw a4,walls_height #a4 : Hauteur du mur
			jal M_intersecteRectangle
			beqz a0,C_collision_mur_suivant #Si le mur n'est pas touche, passe au suivant
			#Sinon, le mur est abime et le missile disparait
			lw t0,4(s7)
			addi t0,t0,-1 #t0 : Decremente la resistance du mur
			sw t0,4(s7) #Stocke la nouvelle resistance
			j C_collision_supprimer_missile
		C_collision_mur_suivant :
			addi s7,s7,8 #s7 : Mur suivant
			addi s8,s8,-1 #s8 : Decremente le compteur de murs
			j C_collision_boucle_murs
	C_collision_cible :
		lw t0,8(s0) #t0 : Direction du missile
		lw t1,missiles_direction_up
		bne t0,t1,C_collision_joueur #Si le missile descend, sa cible est le joueur
		#Sinon, sa cible est un envahisseur
		addi s7,s2,8 #s7 : Adresse de l'envahisseur courant
		lw s8,invaders_number #s8 : Compteur d'envahisseurs
		lw s9,invaders_alive_status #s9 : Statut d'un envahisseur vivant
		C_collision_boucle_envahisseurs :
			beqz s8,C_collision_missile_suivant #Si aucun envahisseur n'est touche, passe au missile suivant
			lw t0,8(s7) #t0 : Statut vital de l'envahisseur
			bne t0,s9,C_collision_envahisseur_suivant #Si l'envahisseur est mort, passe au suivant
			mv a0,s0 #a0 : Adresse du missile
			lw a1,0(s7) #a1 : Abscisse de l'envahisseur
			lw a2,4(s7) #a2 : Ordonnee de l'envahisseur
			lw a3,invaders_width #a3 : Largeur de l'envahisseur
			lw a4,invaders_height #a4 : Hauteur de l'envahisseur
			jal M_intersecteRectangle
			beqz a0,C_collision_envahisseur_suivant #Si l'envahisseur n'est pas touche, passe au suivant
			#Sinon, l'envahisseur est detruit
			lw t0,invaders_dead_status
			sw t0,8(s7) #L'envahisseur meurt
			lw t0,4(s2)
			addi t0,t0,-1 #t0 : Decremente le nombre d'envahisseurs en vie
			sw t0,4(s2) #Stocke le nouveau nombre d'envahisseurs en vie
			lw t0,invaders_points
			add s5,s5,t0 #s5 : Ajoute les points de l'envahisseur
			jal S_explosion
			j C_collision_supprimer_missile
		C_collision_envahisseur_suivant :
			addi s7,s7,12 #s7 : Envahisseur suivant
			addi s8,s8,-1 #s8 : Decremente le compteur d'envahisseurs
			j C_collision_boucle_envahisseurs
	C_collision_joueur :
		mv a0,s0 #a0 : Adresse du missile
		lw a1,0(s3) #a1 : Abscisse du joueur
		lw a4,player_height #a4 : Hauteur du joueur
		lw t0,I_hauteur
		sub a2,t0,a4 #a2 : Ordonnee du joueur, colle au bas de l'ecran
		lw a3,player_width #a3 : Largeur du joueur
		jal M_intersecteRectangle
		beqz a0,C_collision_missile_suivant #Si le joueur n'est pas touche, passe au missile suivant
		#Sinon, le joueur perd une vie
		lw t0,4(s3)
		addi t0,t0,-1 #t0 : Decremente le nombre de vies
		sw t0,4(s3) #Stocke le nouveau nombre de vies
		li s6,1 #s6 : Le joueur a ete touche
		jal S_touche
	C_collision_supprimer_missile :
		lw t0,missiles_not_exist_status
		sw t0,12(s0) #Le missile disparait
	C_collision_missile_suivant :
		addi s0,s0,16 #s0 : Missile suivant
		addi s4,s4,-1 #s4 : Decremente le compteur de missiles
		j C_collision_boucle_missiles
	#Epilogue
	C_collision_fin :
		mv a0,s5 #a0 : Points gagnes
		mv a1,s6 #a1 : 1 si le joueur a ete touche
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		lw s3,16(sp)
		lw s4,20(sp)
		lw s5,24(sp)
		lw s6,28(sp)
		lw s7,32(sp)
		lw s8,36(sp)
		lw s9,40(sp)
		addi sp,sp,44
		jr ra
	#Fin epilogue
