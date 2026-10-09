####################################################################################################
#                                 TEST VISUEL : AFFICHAGE (prefixe T_)                             #
####################################################################################################
#
# A lancer dans RARS avec le Bitmap Display connecte (memes reglages que le jeu).
# Un carre vert de 5x5 units traverse l'ecran de gauche a droite : verifie le double buffer
# (I_creer, I_effacer, I_rectangle, I_buff_to_visu).

.text
	j T_main

.include "../src/config.s"
.include "../src/affichage.s"

.text

T_main :
	jal I_creer
	sw a0,I_visu,t0 #Alloue l'image affichee (debut du tas)
	jal I_effacer
	jal I_creer
	sw a0,I_buff,t0 #Alloue le buffer
	jal I_effacer
	li s0,0 #s0 : Abscisse du carre
	lw s1,I_largeur
	addi s1,s1,-5 #s1 : Abscisse maximale du carre
	T_main_boucle :
		bgt s0,s1,T_main_fin #Si le carre a traverse l'ecran, fin du test
		lw a0,I_buff
		jal I_effacer #Efface le buffer
		mv a0,s0 #a0 : Abscisse du carre
		li a1,10 #a1 : Ordonnee du carre
		li a2,5 #a2 : Largeur
		li a3,5 #a3 : Hauteur
		li a4,0x0000ff00 #a4 : Vert
		jal I_rectangle #Dessine le carre dans le buffer
		jal I_buff_to_visu #Affiche le buffer
		li a0,50
		li a7,32
		ecall #Attend 50 ms
		addi s0,s0,1 #s0 : Avance le carre
		j T_main_boucle
	T_main_fin :
		li a7,10
		ecall
