####################################################################################################
#                                        SON (prefixe S_)                                          #
####################################################################################################
#
# Effets sonores via l'appel systeme MIDI asynchrone de RARS (ecall 31) : le jeu n'est pas bloque
# pendant que la note est jouee. Les sons peuvent etre coupes avec sound_enabled dans config.s.
#
# Depend de : config.s

.data

#Notes MIDI : hauteur (0-127), duree (ms), instrument (0-127)
sound_shot_pitch : .word 84
sound_shot_duration : .word 60
sound_shot_instrument : .word 80
sound_explosion_pitch : .word 40
sound_explosion_duration : .word 150
sound_explosion_instrument : .word 127
sound_hit_pitch : .word 30
sound_hit_duration : .word 400
sound_hit_instrument : .word 118
sound_volume : .word 90

.text

#Resume :
#	Joue une note sans bloquer le programme, si les sons sont actives
#Preconditions : //
#Entrees :
#	a0 : Hauteur de la note (0-127)
#	a1 : Duree en millisecondes
#	a2 : Instrument (0-127)
#Sorties : //
S_jouer :
	#Prologue
	addi sp,sp,-20
	sw ra,0(sp)
	sw a0,4(sp)
	sw a1,8(sp)
	sw a2,12(sp)
	sw a3,16(sp)
	#Fin prologue
	lw t0,sound_enabled #t0 : 1 si les sons sont actives
	beqz t0,S_jouer_fin #Si les sons sont desactives, fin de la fonction
	lw a3,sound_volume #a3 : Volume
	li a7,31
	ecall #Joue la note (MIDI asynchrone)
	#Epilogue
	S_jouer_fin :
		lw ra,0(sp)
		lw a0,4(sp)
		lw a1,8(sp)
		lw a2,12(sp)
		lw a3,16(sp)
		addi sp,sp,20
		jr ra
	#Fin epilogue

#Resume :
#	Joue le son d'un tir du joueur
#Preconditions : //
#Entrees : //
#Sorties : //
S_tir :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	lw a0,sound_shot_pitch
	lw a1,sound_shot_duration
	lw a2,sound_shot_instrument
	jal S_jouer
	#Epilogue
	lw ra,0(sp)
	addi sp,sp,4
	jr ra
	#Fin epilogue

#Resume :
#	Joue le son de la destruction d'un envahisseur
#Preconditions : //
#Entrees : //
#Sorties : //
S_explosion :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	lw a0,sound_explosion_pitch
	lw a1,sound_explosion_duration
	lw a2,sound_explosion_instrument
	jal S_jouer
	#Epilogue
	lw ra,0(sp)
	addi sp,sp,4
	jr ra
	#Fin epilogue

#Resume :
#	Joue le son du joueur touche
#Preconditions : //
#Entrees : //
#Sorties : //
S_touche :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	lw a0,sound_hit_pitch
	lw a1,sound_hit_duration
	lw a2,sound_hit_instrument
	jal S_jouer
	#Epilogue
	lw ra,0(sp)
	addi sp,sp,4
	jr ra
	#Fin epilogue
