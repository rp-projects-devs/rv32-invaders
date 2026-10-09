####################################################################################################
#                                     AFFICHAGE (prefixe I_)                                       #
####################################################################################################
#
# Gestion de l'image : allocation, dessin de units et de rectangles, double buffer.
# Tout le dessin se fait dans I_buff, puis I_buff_to_visu recopie le buffer dans I_visu,
# la zone memoire lue par le Bitmap Display. Cela evite de voir l'image se construire (scintillement).
#
# Depend de : config.s

.data

I_visu : .word 0 #Adresse de l'image affichee par le Bitmap Display
I_buff : .word 0 #Adresse du buffer dans lequel on dessine
I_largeur : .word 0 #Largeur de l'image en units, calculee par I_creer
I_hauteur : .word 0 #Hauteur de l'image en units, calculee par I_creer
I_nb_unit : .word 0 #Nombre total de units de l'image, calcule par I_creer

.text

#Resume :
#	Calcule la largeur de l'image en nombre de units
#Preconditions : largeur en pixels / largeur d'un unit est entier
#Entrees : //
#Sorties :
#	a0 : Largeur en nombre de units
I_largeur_fct :
	#Prologue
	addi sp,sp,-8
	sw s0,0(sp)
	sw s1,4(sp)
	#Fin prologue
	lw s0,I_largeur_ecran #s0 : Largeur de l'ecran en pixels
	lw s1,I_largeur_unit #s1 : Largeur d'un unit en pixels
	div a0,s0,s1 #a0 : Largeur en units
	#Epilogue
	lw s0,0(sp)
	lw s1,4(sp)
	addi sp,sp,8
	jr ra
	#Fin epilogue

#Resume :
#	Calcule la hauteur de l'image en nombre de units
#Preconditions : hauteur en pixels / hauteur d'un unit est entier
#Entrees : //
#Sorties :
#	a0 : Hauteur en nombre de units
I_hauteur_fct :
	#Prologue
	addi sp,sp,-8
	sw s0,0(sp)
	sw s1,4(sp)
	#Fin prologue
	lw s0,I_hauteur_ecran #s0 : Hauteur de l'ecran en pixels
	lw s1,I_hauteur_unit #s1 : Hauteur d'un unit en pixels
	div a0,s0,s1 #a0 : Hauteur en units
	#Epilogue
	lw s0,0(sp)
	lw s1,4(sp)
	addi sp,sp,8
	jr ra
	#Fin epilogue

#Resume :
#	Alloue dans le tas la memoire d'une image et met a jour I_largeur, I_hauteur et I_nb_unit
#Preconditions : //
#Entrees : //
#Sorties :
#	a0 : Adresse de la memoire allouee pour l'image
I_creer :
	#Prologue
	addi sp,sp,-12
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	#Fin prologue
	jal I_largeur_fct
	sw a0,I_largeur,s0 #Sauvegarde la largeur en units
	mv s0,a0 #s0 : Largeur en units
	jal I_hauteur_fct
	sw a0,I_hauteur,s1 #Sauvegarde la hauteur en units
	mv s1,a0 #s1 : Hauteur en units
	mul s1,s0,s1 #s1 : Largeur * hauteur
	sw s1,I_nb_unit,s0 #Sauvegarde le nombre de units
	slli s1,s1,2 #s1 : Nombre d'octets a reserver (4 octets par unit)
	mv a0,s1 #a0 : Nombre d'octets a reserver
	li a7,9
	ecall #Alloue la memoire dans le tas (sbrk)
	#Epilogue
	lw ra,0(sp)
	lw s0,4(sp)
	lw s1,8(sp)
	addi sp,sp,12
	jr ra
	#Fin epilogue

#Resume :
#	Convertit les coordonnees d'un unit en son adresse dans le buffer
#Preconditions : 0 <= abscisse < I_largeur et 0 <= ordonnee < I_hauteur
#Entrees :
#	a0 : Abscisse du unit
#	a1 : Ordonnee du unit
#Sorties :
#	a0 : Adresse du unit dans I_buff
I_xy_to_addr :
	#Prologue
	addi sp,sp,-12
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	#Fin prologue
	mv s1,a0 #s1 : Abscisse du unit
	lw s0,I_largeur #s0 : Largeur en units
	mul s0,a1,s0 #s0 : Ordonnee * largeur
	add s0,s0,s1 #s0 : Numero du unit en une dimension
	slli a0,s0,2 #a0 : Decalage en octets
	lw s0,I_buff #s0 : Adresse du buffer
	add a0,a0,s0 #a0 : Adresse associee au unit
	#Epilogue
	lw ra,0(sp)
	lw s0,4(sp)
	lw s1,8(sp)
	addi sp,sp,12
	jr ra
	#Fin epilogue

#Resume :
#	Convertit l'adresse d'un unit du buffer en ses coordonnees
#Preconditions : a0 fait partie des adresses allouees pour I_buff
#Entrees :
#	a0 : Adresse du unit
#Sorties :
#	a0 : Abscisse du unit
#	a1 : Ordonnee du unit
I_addr_to_xy :
	#Prologue
	addi sp,sp,-12
	sw ra,0(sp)
	sw s0,4(sp)
	sw s2,8(sp)
	#Fin prologue
	lw s0,I_buff #s0 : Adresse du buffer
	sub s2,a0,s0 #s2 : Decalage en octets
	srli s2,s2,2 #s2 : Numero du unit en une dimension
	lw s0,I_largeur #s0 : Largeur en units
	div a1,s2,s0 #a1 : Ordonnee du unit
	rem a0,s2,s0 #a0 : Abscisse du unit
	#Epilogue
	lw ra,0(sp)
	lw s0,4(sp)
	lw s2,8(sp)
	addi sp,sp,12
	jr ra
	#Fin epilogue

#Resume :
#	Colorie un unit du buffer
#Preconditions :
#	0 <= abscisse < I_largeur et 0 <= ordonnee < I_hauteur
#	Couleur au format 0x00RRGGBB
#Entrees :
#	a0 : Abscisse du unit
#	a1 : Ordonnee du unit
#	a2 : Couleur du unit
#Sorties : //
I_plot :
	#Prologue
	addi sp,sp,-8
	sw ra,0(sp)
	sw a0,4(sp)
	#Fin prologue
	jal I_xy_to_addr #a0 : Adresse du unit
	sw a2,0(a0) #Colorie le unit
	#Epilogue
	lw ra,0(sp)
	lw a0,4(sp)
	addi sp,sp,8
	jr ra
	#Fin epilogue

#Resume :
#	Remplit une image de noir
#Preconditions : L'image a ete allouee avec I_creer
#Entrees :
#	a0 : Adresse de depart de l'image
#Sorties : //
I_effacer :
	#Prologue
	addi sp,sp,-16
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	#Fin prologue
	mv s0,a0 #s0 : Adresse mouvante
	li s2,0x00000000 #s2 : Couleur noire
	lw s1,I_nb_unit #s1 : Compteur de units
	I_effacer_boucle :
		beqz s1,I_effacer_fin #Si tous les units sont noirs, fin de la fonction
		sw s2,0(s0) #Colorie le unit en noir
		addi s0,s0,4 #s0 : Unit suivant
		addi s1,s1,-1 #s1 : Decremente le compteur de units
		j I_effacer_boucle
	#Epilogue
	I_effacer_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		addi sp,sp,16
		jr ra
	#Fin epilogue

#Resume :
#	Dessine un rectangle plein dans le buffer
#Preconditions :
#	0 <= abscisse et abscisse + largeur <= I_largeur
#	0 <= ordonnee et ordonnee + hauteur <= I_hauteur
#	Couleur au format 0x00RRGGBB
#Entrees :
#	a0 : Abscisse du coin superieur gauche
#	a1 : Ordonnee du coin superieur gauche
#	a2 : Largeur du rectangle
#	a3 : Hauteur du rectangle
#	a4 : Couleur
#Sorties : //
I_rectangle :
	#Prologue
	addi sp,sp,-32
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw a0,12(sp)
	sw a1,16(sp)
	sw a2,20(sp)
	sw a3,24(sp)
	sw a4,28(sp)
	#Fin prologue
	mv s0,a0 #s0 : Sauvegarde de l'abscisse de depart pour chaque ligne
	add s1,a2,a0 #s1 : Abscisse de fin (exclue)
	mv a2,a4 #a2 : Couleur, reorganisation des arguments pour I_plot
	add a3,a3,a1 #a3 : Ordonnee de fin (exclue)
	I_rectangle_boucle_ligne :
		bge a1,a3,I_rectangle_fin #Si toutes les lignes sont dessinees, fin de la fonction
		I_rectangle_boucle_colonne :
			bge a0,s1,I_rectangle_ligne_suivante #Si la ligne est dessinee, passe a la suivante
			jal I_plot #Colorie le unit (a0,a1)
			addi a0,a0,1 #a0 : Colonne suivante
			j I_rectangle_boucle_colonne
		I_rectangle_ligne_suivante :
			mv a0,s0 #a0 : Retour en debut de ligne
			addi a1,a1,1 #a1 : Ligne suivante
			j I_rectangle_boucle_ligne
	#Epilogue
	I_rectangle_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw a0,12(sp)
		lw a1,16(sp)
		lw a2,20(sp)
		lw a3,24(sp)
		lw a4,28(sp)
		addi sp,sp,32
		jr ra
	#Fin epilogue

#Resume :
#	Recopie le buffer dans l'image affichee
#Preconditions : I_buff et I_visu ont ete alloues
#Entrees : //
#Sorties : //
I_buff_to_visu :
	#Prologue
	addi sp,sp,-20
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	sw s3,16(sp)
	#Fin prologue
	lw s0,I_buff #s0 : Adresse mouvante dans le buffer
	lw s1,I_visu #s1 : Adresse mouvante dans l'image affichee
	lw s2,I_nb_unit #s2 : Compteur de units
	I_buff_to_visu_boucle :
		beqz s2,I_buff_to_visu_fin #Si tous les units sont copies, fin de la fonction
		lw s3,0(s0) #s3 : Couleur du unit dans le buffer
		sw s3,0(s1) #Copie la couleur dans l'image affichee
		addi s0,s0,4 #s0 : Unit suivant du buffer
		addi s1,s1,4 #s1 : Unit suivant de l'image affichee
		addi s2,s2,-1 #s2 : Decremente le compteur de units
		j I_buff_to_visu_boucle
	#Epilogue
	I_buff_to_visu_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		lw s3,16(sp)
		addi sp,sp,20
		jr ra
	#Fin epilogue
