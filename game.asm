######################################################################
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 1024
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# - Milestone 3
#
# Which approved features have been implemented for milestone 3?
# 1. Increase in difficulty as game progresses.
#	Game speed increases as all obstacles pass the left border once. Then the counter is reset.
#	In some time, the game speed reaches its maximum.
# 2. Ability to shoot
#	The player can shoot to the obstacles to destroy them.
#	Laser count is initially 3, and decreases as the player shoots.
# 3. 2 types of pick-ups
#	Health Pick-up
#		The player's health is initially 3, as he collides with an obstacle he loses one health.
#		Health pick-up gives an health to the player, but he cannot have more than 3 health.
#	Laser Pick-up
#		The player can shoot to the obstacles to destroy them.
#		Laser count is initially 3, and decreases as the player shoots.
#		Laser pick-up gives a laser to the player, but he cannot have more than 3 laser.
#
# Link to video demonstration for final submission:
# - https://play.library.utoronto.ca/watch/2a9cd283e1afe11379ac3699ef2e3f75
#
# Are you OK with us sharing the video with people outside course staff?
# - Yes (for video and code)
# - GitHub Link: https://github.com/pasaaliaslan/CSCB58_SpaceGame
#
# Any additional information that the TA needs to know:
# - Pick-Up Mechanism can work improperly when ship makes fast move to collect a pick-up.
# - Collusions may seem to be delayed on the screen. This is because obstacles move by 2 pixel to the left while ship moves by 1 and laser moves by 1 pixel to the right. 
#
#####################################################################

.data

shipAddr: 		.word 	0x10008000
obstacle1Addr:		.word 	0x10008000
obstacle2Addr:		.word 	0x10008000
obstacle3Addr:		.word 	0x10008000
textAddr:		.word 	0x10008000

white:			.word 	0xffffff 
darkGray:		.word 	0xaaaaaa
lightGray:		.word 	0xcccccc
black:			.word 	0x000000
obsColor:		.word	0xc7b369
healthColor:		.word	0xff0000
laserColor:		.word	0x00ddff

keyLocation:		.word 	0xffff0000


.text

#=============================================================================================================================================================================
#=============================================================================================================================================================================
#=============================================================================== Main Function ===============================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
START:
	jal clearScreen			# Clears the screen

	lw $s0	obsColor		# $s0 stores the color of the obstacles.
	lw $s1, white			# $s1 stores the white color code.
	lw $s2, darkGray		# $s2 stores the darkGray color code.
	lw $s3, lightGray		# $s3 stores the lightGray color code.
	lw $s4, black			# $s4 stores the black color code.
	lw $s5, textAddr		# $s5 stores the base address for laser,health, game over texts.
	lw $s6, healthColor		# $s6 stores the health color code.
	lw $s7, laserColor		# $s7 stores the laser color code.
	
	lw $t0, shipAddr 		# $t0 stores the base address for ship.
	addi $t0, $t0, 13880		# Sets a the ship in the middle of left border.
	
	lw $t1, obstacle1Addr 		# $t1 stores the base address for obstacle 1.
	addi $t1, $t1, 900
	
	lw $t2, obstacle2Addr 		# $t2 stores the base address for obstacle 2.
	addi $t2, $t2, 8492
	
	lw $t3, obstacle3Addr 		# $t3 stores the base address for obstacle 3.
	addi $t3, $t3, 18896
	
	add $t4, $s5, $zero		# $t4 stores the location of the pick up.
	
	add $t5, $zero, $zero		# $t5 stores how many of the obstacles has passed the left border, resets to 0 when all three has passed once, then starts counting again.
	addi $t6, $zero, 8		# $t6 stores the speed of the game (initially 5).
	add $a3, $zero, $zero		# $a3 is an iterator to keep track of speed.
	
	add $t7, $s5, $zero		# $t7 stores the location of the laser (initally 0 to indicate that laser is not fired).
	
	add $t8, $s4, $zero		# $t8 stores the color of the pick up.
	
	lw $t9, keyLocation		# $t9 stores Keyboard Event.
	
	add $a0, $s6, $zero
	jal drawHealth1
	jal drawHealth2
	jal drawHealth3
	
	add $a0, $s7, $zero
	jal drawLaser1
	jal drawLaser2
	jal drawLaser3
	
gameLoop: 
	lw $a0, 26640($s5)		# $a0 stores the color of the specific pixel where there should be the first health indicator.
	beq $a0, $s4, gameOver		# Branch (i.e. go to game over screen) if the place of the first health is black (should be red, if there is health).
	
	beq $t7, $s5, gameLoopObstacles	# Branch to draw obstacles, if there is no laser in the game.
gameLoopLaser:
	add $a0, $s7, $zero		# Set laser color.
	jal drawShipLaser		# Draw Ship laser, if it is on screen.
	
gameLoopObstacles:
	add $a0, $zero, $s0		# Set obstacle color to brown.
	add $a1, $zero, $t1		# Sets the coordinates of the 1st obstacle.
	jal drawObstacle		# Draws the 1st obstacle.
	
	add $a1, $zero, $t2		# Sets the coordinates of the 2nd obstacle.
	jal drawObstacle		# Draws the 2nd obstacle.
	
	add $a1, $zero, $t3 		# Sets the coordinates of the 3rd obstacle.
	jal drawObstacle		# Draws the 3rd obstacle.
	
	bne $t4, $s5, gameLoopShip	# Branch to draw ship, if there is already an health pick-up on the screen.
gameLoopPickUp:
	jal generatePickUpAddr		# Generate Pick-Up location, if none.
	add $t4, $v1, $zero		# Update the location of the pick-up.
	
	beq $t4, $s5, gameLoopShip	# If no address generated, then dont draw pick-up.
	
	jal generatePickUpColor		# Generate Pick-Up color, if none.
	add $t8, $v1, $zero		# Update the color of the pick-up.
	
	add $a0, $t4, $zero		# $a0 is the argument for pick-up address.
	add $a1, $t8, $zero		# $a1 is the argument for pick-up color.
	jal drawPickUp
	
gameLoopShip:
	add $a0, $s3, $zero		# Set color arguments.
	add $a1, $s1, $zero		
	add $a2, $s2, $zero
	jal drawShip			# Draws the ship.
	
	bne $t4, $s5, loopDelay		# Branch to draw ship, if there is already an health pick-up on the screen.
	bne $t8, $s5, loopDelay		# Branch to draw ship, if there is already an laser pick-up on the screen.
	
loopDelay:
	li $v0, 32			# Delay.
	li $a0, 40 			# (40 milliseconds).
	syscall
	
	addi $a3, $a3, 1		# Increase speed iterator.
	
	lw $a1, 0($t9)			# Check Key event.
	bne $a1, 1, loopCheckLaser	# If no key is pressed, then don't delete ship.
	lw $a1, 4($t9) 			# Make key event recognizable by ascii codes.
	
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $t0, 0($sp)			# Push initial ship address onto the stack.

loopKeyActivity:
	beq $a1, 112, START		# If keypress is 'p', branch to START (Restart Condition).
	beq $a1, 97, shipMoveLeft	# If keypress is 'a', branch to moveLeft.
	beq $a1, 100, shipMoveRight	# Else if keypress is 'd', branch to moveRight.
	beq $a1, 115, shipMoveDown	# Else if keypress is 's', branch to moveDown.
	beq $a1, 119, shipMoveUp	# Else if keypress is 'w', branch to moveUp.
	beq $a1, 107, shoot		# Else if keypress is 'k', branch to shoot.

	beq $a1, 80, START		# If keypress is 'p', branch to START (Restart Condition).
	beq $a1, 65, shipMoveLeft	# If keypress is 'a', branch to moveLeft.
	beq $a1, 68, shipMoveRight	# Else if keypress is 'd', branch to moveRight.
	beq $a1, 83, shipMoveDown	# Else if keypress is 's', branch to moveDown.
	beq $a1, 87, shipMoveUp		# Else if keypress is 'w', branch to moveUp.
	beq $a1, 75, shoot		# Else if keypress is 'k', branch to shoot.
	
loopEraseShip:
	add $v0, $t0, $zero

	lw $t0 0($sp)			# Pop key event from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.	
	
	add $a0, $s4, $zero		# Set color arguments.
	add $a1, $s4, $zero
	add $a2, $s4, $zero
	jal drawShip			# Erases the ship.
	
	add $t0, $v0, $zero
	add $v0, $zero, $zero
	
loopCheckLaser:
	beq $t7, $s5, loopEraseObs	# Laser location is the top-left corner, then the laser is not in the game, so no need to move it.
	
loopEraseLaser:
	add $a0, $s4, $zero		# Set laser color to black (i.e. erase it).
	jal drawShipLaser		# Erase laser.
	jal moveShipLaser		# Moves the laser.
	
loopEraseObs:
	bne $t6, $a3, loopPickUp	# If speed iterator doesn't reach to max, don't move obstacles.
	
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $t1, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $t2, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $t3, 0($sp)			# Push return addres onto the stack.
	
	add $a0, $zero, $t1	
	jal moveObstacle		# Moves the 1st obstacle.
	add $t1, $zero, $v0
	
	add $a0, $zero, $t2	
	jal moveObstacle		# Moves the 2nd obstacle.
	add $t2, $zero, $v0
	
	add $a0, $zero, $t3	
	jal moveObstacle		# Moves the 3rd obstacle.
	add $t3, $zero, $v0
	
	add $a0, $zero, $s4		# Sets the obstacle colors to black (to erase them).
	
	lw $a1 0($sp)			# $a1 now stores the base address of 3rd obstacle.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jal drawObstacle		# Undraws the 3rd obstacle.
	
	lw $a1 0($sp)			# $a1 now stores the base address of 2nd obstacle.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jal drawObstacle		# Undraws the 2nd obstacle.
	
	lw $a1 0($sp)			# $a1 now stores the base address of 1st obstacle.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jal drawObstacle		# Undraws the 1st obstacle.
	
	add $a3, $zero, $zero		# Reset speed iterator.
	
	li $v0, 1
	move $a0, $t6
	syscall
	
loopPickUp:
	beq $t4, $s5, gameLoop
	add $a0, $t4, $zero
	add $a1, $t8, $zero
	jal checkPickUpCollusion

	j gameLoop			# Jump back to the loop start.
	
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#============================================================================= Pick-up Mechanism =============================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
# Draw Pick-up Function
drawPickUp:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 512($a0)
	sw $a1, 516($a0)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

# Generate Pick-up Address Function
generatePickUpAddr:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	add $v1, $s5, $zero
	
	li $v0, 42        		# Service 42, random int range.
	li $a0, 0          		# Select random generator 0.
	li $a1, 200         		# Select upper bound of random number.
	syscall            		# Generate random int (returns in $a0).
	
	bne $a0, 5, generatePickUpReturn
	
	li $v0, 42        		# Service 42, random int range.
	li $a0, 0          		# Select random generator 0.
	li $a1, 30         		# Select upper bound of vertical offset.
	syscall            		# Generate random int (returns in $a0).
	
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0		# $a0 = $a0 x 512
	
	add $v1, $v1, $a0
	
	li $v0, 42        		# Service 42, random int range.
	li $a0, 0          		# Select random generator 0.
	li $a1, 80         		# Select upper bound of horizontal offset.
	syscall            		# Generate random int (returns in $a0).

	add $a0, $a0, $a0
	add $a0, $a0, $a0		
	add $a0, $a0, 80		# $a0 = $a0 x 4 + 80
	
	add $v1, $v1, $a0
	
generatePickUpReturn:	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

# Generate pick-up Color Function
generatePickUpColor:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
keepGenerateColor:
	li $v0, 42        		# Service 42, random int range.
	li $a0, 0          		# Select random generator 0.
	li $a1, 3         		# Select upper bound of vertical offset.
	syscall            		# Generate random int (returns in $a0).
	
	beq $a0, 1, generatedHealth
	beq $a0, 2, generatedLaser
	
	j keepGenerateColor

generatedHealth:
	add $v1, $s6, $zero
	j generatePickUpColorReturn
generatedLaser:
	add $v1, $s7, $zero
	j generatePickUpColorReturn
generatePickUpColorReturn:
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra


checkPickUpCollusion:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	lw $v0, 0($a0)
	beq $v0, $s1, shipCollected
	beq $v0, $s2, shipCollected
	beq $v0, $s3, shipCollected
	bne $v0, $a1, pickUpBroken
	
	lw $v0, 4($a0)
	beq $v0, $s1, shipCollected
	beq $v0, $s2, shipCollected
	beq $v0, $s3, shipCollected
	bne $v0, $a1, pickUpBroken
	
	lw $v0, 512($a0)
	beq $v0, $s1, shipCollected
	beq $v0, $s2, shipCollected
	beq $v0, $s3, shipCollected
	bne $v0, $a1, pickUpBroken
	
	lw $v0, 516($a0)
	beq $v0, $s1, shipCollected
	beq $v0, $s2, shipCollected
	beq $v0, $s3, shipCollected
	bne $v0, $a1, pickUpBroken
	
	j checkPickUpCollusionReturn
	
	
shipCollected:
	beq $a1, $s6, pickUpWasHealth
	beq $a1, $s7, pickUpWasLaser
	
pickUpWasHealth:
	jal addHealth
	j pickUpBroken
	
pickUpWasLaser:
	jal addLaser
	
pickUpBroken:
	add $a1, $s4, $zero
	jal drawPickUp
	add $t4, $s5, $zero
	add $t8, $s4, $zero
	
checkPickUpCollusionReturn:
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#========================================================================= Movement of the Spaceship =========================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
# Ship's Left Movement
shipMoveLeft:
	addi $a0, $s5, 40		# $a0 is an iterator, initially screenAddress.
	addi $a1, $s5, 20008		# $a1 stores the bottom-left pixel coordinates.
checkLeftBorder:
	beq $a1, $a0, canMoveLeft	# If $a1 = $a0 (iterator reaches to the upperlimit), then it means that ship has not reached left border.
	beq $t0, $a0, loopCheckLaser	# If $t0 = $a0, then it means that the ship has reached to one of the leftmost pixels.
	addi $a0, $a0, 512		# Increase iterator.
	j checkLeftBorder		# LOOP.
canMoveLeft:
	subi $t0, $t0, 4		# If 'a' is pressed, and ship is inside borders, apply horizontal offset to memory loaction of the ship.
	j loopEraseShip			# Jump back to loopEnd.

# Ship's Up Movement
shipMoveUp:
	addi $a0, $s5, 40		# $a0 is an iterator, initially screenAddress + 40 (leftmost pixel).
	addi $a1, $s5, 424		# $a1 stores the top-right pixel coordinates.
checkTopBorder:
	beq $a1, $a0, canMoveUp		# If $a1 = $a0 (iterator reaches to the upperlimit), then it means that ship has not reached top border.
	beq $t0, $a0, loopCheckLaser	# If $t0 = $a0, then it means that the ship has reached to one of the topmost pixels.
	addi $a0, $a0, 4		# Increase iterator.
	j checkTopBorder		# LOOP.
canMoveUp:
	subi $t0, $t0, 512		# If 'w' is pressed, and ship is inside borders, apply vertical offset to memory loaction of the ship.
	j loopEraseShip			# Jump back to loopEnd.
	
# Ship's Right movement
shipMoveRight:
	addi $a0, $s5, 424		# $a0 is an iterator, initially screenAddress + 424 (top-right pixel).
	addi $a1, $s5, 20392		# $a1 stores the bottom-right pixel coordinates.
checkRightBorder:
	beq $a1, $a0, canMoveRight	# If $a1 = $a0 (iterator reaches to the upperlimit), then it means that ship has not reached right border.
	beq $t0, $a0, loopCheckLaser	# If $t0 = $a0, then it means that the ship has reached to one of the rightmost pixels.
	addi $a0, $a0, 512		# Increase iterator.	
	j checkRightBorder		# LOOP.
canMoveRight:
	addi $t0, $t0 4			# If 'd' is pressed, and ship is inside borders, apply horizontal offset to memory loaction of the ship.
	j loopEraseShip			# Jump back to loopEnd.

# Ship's Down movement
shipMoveDown:
	add $a0, $s5, 19496		# $a0 is an iterator, initially screenAddress + 19492 (indicating the last row of the screen).
	addi $a1, $s5, 20008		# $a1 stores the bottom-right pixel coordinates.
checkBottomBorder:
	beq $a1, $a0, canMoveDown	# If $a1 = $a0 (iterator reaches to the upperlimit), then it means that ship has not reached bottom border.
	beq $t0, $a0, loopCheckLaser	# If $t0 = $a0, then it means that the ship has reached to one of the bottommost pixels.
	addi $a0, $a0, 4		# Increase iterator.	
	j checkBottomBorder		# LOOP.
canMoveDown:
	addi $t0, $t0, 512		# If 's' is pressed apply vertical offset to memory loaction of the ship.
	j loopEraseShip			# Jump back to loopEnd.
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#============================================================================= Health Indicators =============================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
	
# Deducing Health Indicators
deduceHealth:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	lw $a0, 26736($s5)		# $a0 stores the color of the 3rd health indicator.
	bne $a0, $s4, deduce3rdHealth	# If there is an indicator there, erase it.
	
	lw $a0, 26688($s5)		# $a0 stores the color of the 2nd health indicator.
	bne $a0, $s4, deduce2ndHealth	# If there is an indicator there, (and by branch above, if 3rd indicator does not exist) erase it.
	
	lw $a0, 26640($s5)		# $a0 stores the color of the 2nd health indicator.
	bne $a0, $s4, deduce1stHealth	# If there is an indicator there, (and by branch above, if 2nd indicator does not exist) erase it.
	
	j deduceHealthReturn
deduce1stHealth:
	add $a0, $s4, $zero		# $a0 stores black color (erase code).
	jal drawHealth1			# Undraw 1st health indicator.
	j deduceHealthReturn		# Jump to the end of the function.
deduce2ndHealth:
	add $a0, $s4, $zero		# $a0 stores black color (erase code).
	jal drawHealth2			# Undraw 2nd health indicator.
	j deduceHealthReturn		# Jump to the end of the function.
deduce3rdHealth:
	add $a0, $s4, $zero		# $a0 stores black color (erase code).
	jal drawHealth3			# Undraw 3rd health indicator.

deduceHealthReturn:
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
# Add Health Indicators
addHealth:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a0, 0($sp)			# Push return addres onto the stack.
	
	lw $a0, 26688($s5)		# $a0 stores the color of the 2nd health indicator.
	beq $a0, $s4, add2ndHealth	# If there is not any indicator there, (and by branch above, if 1st indicator exists) add it.
	
	lw $a0, 26736($s5)		# $a0 stores the color of the 3rd health indicator.
	beq $a0, $s4, add3rdHealth	# If there is not any indicator there, (and by branch above, if 2nd indicator exists) add it.
	
	j addHealthReturn
add2ndHealth:
	add $a0, $s6, $zero		# $a0 stores health color.
	jal drawHealth2			# Draw 2nd laser indicator.
	j addHealthReturn		# Jump to the end of the function.
add3rdHealth:
	add $a0, $s6, $zero		# $a0 stores health color.
	jal drawHealth3			# Draw 3rd laser indicator.

addHealthReturn:
	lw $a0 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#============================================================================= Laser  Indicators =============================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================

# Shooting Mechanism
shoot:
	lw $a0, 26812($s5)		# $a0 stores the color of the pixel where there should be the first laser indicator.
	beq $a0, $s4, loopCheckLaser	# Jump to loopCheckLaser (i.e. don't shoot) if there is no laser indicator in the place of the first laser indicator.
	bne $t7, $s5, loopCheckLaser	# If a laser is still on the screen, then don't shoot another.
	
	add $t7, $t0, $zero		# $t7 is updated to store the location of the ship.
	addi $t7, $t7, 2644		# $t7 is updated to store the location of the tip of the ship, where laser will be fired.
	
	jal deduceLaser			# Deduce a laser from the laser indicators (by branch above, it is certain that there will be at least one indicator.
	
	jal drawShipLaser		# Draw the initial instance of the laser.
	
	j loopCheckLaser		# Jump back to loopEnd.
	
# Deducing Laser Indicators
deduceLaser:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a0, 0($sp)			# Push $a0 onto the stack.
	
	lw $a0, 26868($s5)		# $a0 stores the color of the 3rd laser indicator.
	bne $a0, $s4, deduce3rdLaser	# If there is an indicator there, erase it.
	
	lw $a0, 26840($s5)		# $a0 stores the color of the 2nd laser indicator.
	bne $a0, $s4, deduce2ndLaser	# If there is an indicator there, (and by branch above, if 3rd indicator does not exist) erase it.
	
	lw $a0, 26812($s5)		# $a0 stores the color of the 1st laser indicator.
	bne $a0, $s4, deduce1stLaser	# If there is an indicator there, (and by branch above, if 2nd indicator does not exist) erase it.
	
	j deduceLaserReturn
deduce1stLaser:
	add $a0, $s4, $zero		# $a0 stores black color (erase code).
	jal drawLaser1			# Undraw 1st laser indicator.
	j deduceLaserReturn		# Jump to the end of the function.
deduce2ndLaser:
	add $a0, $s4, $zero		# $a0 stores black color (erase code).
	jal drawLaser2			# Undraw 2nd laser indicator.
	j deduceLaserReturn		# Jump to the end of the function.
deduce3rdLaser:
	add $a0, $s4, $zero		# $a0 stores black color (erase code).
	jal drawLaser3			# Undraw 3rd laser indicator.

deduceLaserReturn:
	lw $a0 0($sp)			# Pop $a0 from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
# Add Laser Indicators
addLaser:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a0, 0($sp)			# Push return addres onto the stack.
	
	lw $a0, 26812($s5)		# $a0 stores the color of the 1st laser indicator.
	beq $a0, $s4, add1stLaser	# If there is not any indicator there, add it.
	
	lw $a0, 26840($s5)		# $a0 stores the color of the 2nd laser indicator.
	beq $a0, $s4, add2ndLaser	# If there is not any indicator there, (and by branch above, if 1st indicator exists) add it.
	
	lw $a0, 26868($s5)		# $a0 stores the color of the 3rd laser indicator.
	beq $a0, $s4, add3rdLaser	# If there is not any indicator there, (and by branch above, if 2nd indicator exists) add it.
	
	j addLaserReturn

add1stLaser:
	add $a0, $s7, $zero		# $a0 stores ;aser color.
	jal drawLaser1			# Draw 1st laser indicator.
	j addLaserReturn		# Jump to the end of the function.
add2ndLaser:
	add $a0, $s7, $zero		# $a0 stores ;aser color.
	jal drawLaser2			# Draw 2nd laser indicator.
	j addLaserReturn		# Jump to the end of the function.
add3rdLaser:
	add $a0, $s7, $zero		# $a0 stores ;aser color.
	jal drawLaser3			# Draw 3rd laser indicator.

addLaserReturn:
	lw $a0 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

#=============================================================================================================================================================================
#=============================================================================================================================================================================
#================================================================================ Ship  Laser ================================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================

drawShipLaser:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sw $a0, 0($t7)
	sw $a0, 4($t7)
	sw $a0, 8($t7)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
moveShipLaser:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	addi $v0, $s5, 500		# v0 is an iterator, initally screen address.
	addi $v1, $s5, 20980		# v1 stores the bottom-left pixel coordinate.

checkShipLaserInBorder:
	beq $v1, $v0, shipLaserGoes	# If $v0 = $v1, then the laser has not reached to the right of the screen, make it move.
	
	addi $v0, $v0, -8
	beq $v0, $t7, laserNotInBorders
	
	addi $v0, $v0, 4
	beq $v0, $t7, laserNotInBorders
	
	addi $v0, $v0, 4
	beq $v0, $t7, laserNotInBorders
	
	addi $v0, $v0, 512		# Increase iterator.
	j checkShipLaserInBorder	# LOOP.
	
laserNotInBorders:
	add $a0, $s4, $zero		# Set laser color to black (i.e. erase it).
	jal drawShipLaser		# Erase laser.
	
	add $t7, $s5, $zero		# $t7 stores the screen address, indicating that it is not fired.
	
	j returnLaserGoes		# Jump to return branch.
	
shipLaserGoes:
	addi $t7, $t7, 8		# Move the laser.		

returnLaserGoes:
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
# Obs Laser Pixel Collusion
laserPixelHitObs:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	add $v1, $t7, $a2		
	
	addi $a1, $a0, 8
	beq $a1, $v1, laserPixelHitObsHit
	addi $a1, $a0, 516
	beq $a1, $v1, laserPixelHitObsHit
	addi $a1, $a0, 1024
	beq $a1, $v1, laserPixelHitObsHit
	addi $a1, $a0, 1536
	beq $a1, $v1, laserPixelHitObsHit
	addi $a1, $a0, 2048
	beq $a1, $v1, laserPixelHitObsHit
	addi $a1, $a0, 2560
	beq $a1, $v1, laserPixelHitObsHit
	addi $a1, $a0, 3076
	beq $a1, $v1, laserPixelHitObsHit
	addi $a1, $a0, 3592
	beq $a1, $v1, laserPixelHitObsHit
	
	j laserPixelHitObsNotHit

laserPixelHitObsHit:
	addi $v1, $zero, 1
	j laserPixelHitObsReturn
	
laserPixelHitObsNotHit:
	addi $v1, $zero, 0

laserPixelHitObsReturn:
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

	
# Obs Laser Collusion
checkLaserHitObs:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	addi $a2, $zero, -24
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, -20
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, -16
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, -12
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, -8
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, -4
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, 0
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, 4
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, 8
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, 12
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, 16
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, 20
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	addi $a2, $zero, 24
	jal laserPixelHitObs
	beq $v1, 1, laserHit
	
	j laserNotHit
	
laserHit:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a0, 0($sp)			# Push obs address onto the stack.
	
	add $a0, $s4, $zero		# Set laser color to black (i.e. erase it).
	jal drawShipLaser		# Erase laser.
	
	lw $a0 0($sp)			# Pop obs address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	
	add $t7, $s5, $zero		# $t7 stores the screen address, indicating that it is not fired.
	addi $v1, $zero, 1		# $v0 stores 1 iff laser hit obstacle, 0 iff not.
	
	j checkLaserHitReturn		# Jump to return.
	
laserNotHit:
	add $v1, $zero, $zero		# If the laser didnt hit any object, then return the obstacle address.
	
checkLaserHitReturn:
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

#=============================================================================================================================================================================
#=============================================================================================================================================================================
#========================================================================= Movement of the Obstacles =========================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
moveObstacle:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sub $v0, $a0, 8			# Update the location of the obstacle.
	
checkObsLaser:
	jal checkLaserHitObs		# Checks if the obstacle had a contact with the laser.
	beq $v1, 1, needObsLocation	# If so, we need new location to start obstacle.
	
	jal checkLeftCollusion
	beq $v1, 1, needObsLocation	# If so, we need new location to start obstacle.
	
	jal checkRightCollusion
	beq $v1, 1, needObsLocation	# If so, we need new location to start obstacle.
	
	jal checkTopCollusion
	beq $v1, 1, needObsLocation	# If so, we need new location to start obstacle.
	
	jal checkBottomCollusion
	beq $v1, 1, needObsLocation	# If so, we need new location to start obstacle.
	
	add $v1, $s5, $zero		# $v1 is an iterator, initially screen address (top-left pixel).
	addi $a1, $s5, 28160		# $a1 stores the coordinate of the bottom-left pixel.
	
checkObsCollusionLoop:
	beq $a1, $v1, returnObsMove	# If $v1 = $a1, then the obstacle has not reached the left border yet.
	
	addi $v1, $v1, -8		# $v1 now stores the 2 pixel left of the current pixel.
	beq $v0, $v1, needObsLocation	# If $v1 = $v0 (i.e. the obstacle's location is equal to this pixel), then it reached to the left border, needs random location on the right.
	
	addi $v1, $v1, 4		# $v1 now stores the 1 pixel left of the current pixel.
	beq $v0, $v1, needObsLocation	# If $v1 = $v0 (i.e. the obstacle's location is equal to this pixel), then it reached to the left border, needs random location on the right.
	
	addi $v1, $v1, 4		# $v1 now stores the current pixel.
	beq $v0, $v1, needObsLocation	# If $v1 = $v0 (i.e. the obstacle's location is equal to this pixel), then it reached to the left border, needs random location on the right.
	
	addi $v1, $v1, 512		# Increase iterator.
	j checkObsCollusionLoop		# LOOP.

needObsLocation:

	li $v0, 42        		# Service 42, random int range.
	li $a0, 0          		# Select random generator 0.
	li $a1, 40         		# Select upper bound of random number.
	syscall            		# Generate random int (returns in $a0).
	
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0
	add $a0, $a0, $a0		# $a0 now stores 512 x $a0.
	
	add $v0, $a0, $s5		# $v0 = $a0 + $s5 (i.e. screen address + random offset).
	addi $v0, $v0, -8		# Set obstacle address to the right of the screen using wrap-up property of the screen.
	addi $v0, $v0, 512		# Set the obstacle one pixel down so that there is no problem when overflow.
	
	addi $t5, $t5, 1
	beq $t6, 1, returnObsMove	# If $t6 == 1, then don't further decrease it.
	bne $t5, 6, returnObsMove	# If all three of the obstacles has not reached to the left border, then don't increase the speed.
		
increaseSpeed:
	add $a3, $zero, $zero		# If $t6 != 0, and all obstacles passed left border then reset $t3.
	add $t5, $zero, $zero		# If $t6 != 0, and all obstacles passed left border then reset $t5.
	addi $t6, $t6, -1		# If $t6 != 0, and all obstacles passed left border, then decrease $t6 by one.
	
returnObsMove:
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	li $v1, 0			# Reset $v1.
	jr $ra

#=============================================================================================================================================================================
#=============================================================================================================================================================================
#========================================================================== Obstacle Ship Collusion ==========================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#Left Part of the Ship (Pixel)
checkLeftCollusionPixel:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a1, 0($sp)			# Push return addres onto the stack.
			
	add $v1, $a0, $a2		# $v1 stores a pixel of obstacle in $a0.
	
	addi $a1, $t0, 0
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 516
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 1032
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 1548
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 2056
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 2568
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 3080
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 3596
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 4122
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 4628
	beq $a1, $v1, isLeftCollusionPixel
	addi $a1, $t0, 5140
	beq $a1, $v1, isLeftCollusionPixel
	
	j notLeftCollusionPixel
	
isLeftCollusionPixel:
	addi $v1, $zero, 1
	j checkLeftCollusionPixelReturn

notLeftCollusionPixel:
	addi $v1, $zero, 0

checkLeftCollusionPixelReturn:
	lw $a1 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

#Left Part of the Ship (Side)
checkLeftCollusion:
	# $a0 - obs address
	# $a2 - obs pixel offset

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a2, 0($sp)			# Push return addres onto the stack.

	addi $a2, $zero, 20
	jal checkLeftCollusionPixel
	beq $v1, 1, isLeftCollided
	
	addi $a2, $zero, 536
	jal checkLeftCollusionPixel
	beq $v1, 1, isLeftCollided
	
	addi $a2, $zero, 1052
	jal checkLeftCollusionPixel
	beq $v1, 1, isLeftCollided
	
	addi $a2, $zero, 1564
	jal checkLeftCollusionPixel
	beq $v1, 1, isLeftCollided
	
	addi $a2, $zero, 2076
	jal checkLeftCollusionPixel
	beq $v1, 1, isLeftCollided
	
	addi $a2, $zero, 2588
	jal checkLeftCollusionPixel
	beq $v1, 1, isLeftCollided
	
	addi $a2, $zero, 3096
	jal checkLeftCollusionPixel
	beq $v1, 1, isLeftCollided
	
	addi $a2, $zero, 3604
	jal checkLeftCollusionPixel
	beq $v1, 1, isLeftCollided
	
	j isNotLeftCollided
	
isLeftCollided:
	addi $v1, $zero, 1
	jal deduceHealth
	j checkLeftCollusionReturn
	
isNotLeftCollided:
	addi $v1, $zero, 0
	
checkLeftCollusionReturn:
	lw $a2 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
# Right Part of the Ship (Pixel)
checkRightCollusionPixel:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a1, 0($sp)			# Push return addres onto the stack.
	
	add $v1, $a0, $a2		# $v1 stores a pixel of obstacle in $a0.
	
	addi $a1, $t0, 16
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 536
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 1080
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 1592
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 2108
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 2640
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 3144
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 3648
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 4144
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 4644
	beq $a1, $v1, isRightCollusionPixel
	addi $a1, $t0, 5144
	beq $a1, $v1, isRightCollusionPixel
	
	j notRightCollusionPixel
	
isRightCollusionPixel:
	addi $v1, $zero, 1
	j checkRightCollusionPixelReturn

notRightCollusionPixel:
	addi $v1, $zero, 0

checkRightCollusionPixelReturn:
	lw $a1 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

# Right Part of the Ship (Side)
checkRightCollusion:
	# $a0 - obs address
	# $a2 - obs pixel offset

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a2, 0($sp)			# Push return addres onto the stack.

	addi $a2, $zero, 8
	jal checkRightCollusionPixel
	beq $v1, 1, isRightCollided
	
	addi $a2, $zero, 516
	jal checkRightCollusionPixel
	beq $v1, 1, isRightCollided
	
	addi $a2, $zero, 1024
	jal checkRightCollusionPixel
	beq $v1, 1, isRightCollided
	
	addi $a2, $zero, 1536
	jal checkRightCollusionPixel
	beq $v1, 1, isRightCollided
	
	addi $a2, $zero, 2048
	jal checkRightCollusionPixel
	beq $v1, 1, isRightCollided
	
	addi $a2, $zero, 2560
	jal checkRightCollusionPixel
	beq $v1, 1, isRightCollided
	
	addi $a2, $zero, 3076
	jal checkRightCollusionPixel
	beq $v1, 1, isRightCollided
	
	addi $a2, $zero, 3592
	jal checkRightCollusionPixel
	beq $v1, 1, isRightCollided
	
	j isNotRightCollided
	
isRightCollided:
	addi $v1, $zero, 1
	jal deduceHealth
	j checkRightCollusionReturn
	
isNotRightCollided:
	addi $v1, $zero, 0
	
checkRightCollusionReturn:
	lw $a2 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
# Top Part of the Ship (Pixel)
checkTopCollusionPixel:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a1, 0($sp)			# Push return addres onto the stack.
	
	add $v1, $a0, $a2		# $v1 stores a pixel of obstacle in $a0.
	
	addi $a1, $t0, 0
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 4
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 8
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 12
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 16
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 532
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 536
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 1052
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 1056
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 1060
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 1576
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 1580
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 1584
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 1588
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 1592
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 2108
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 2624
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 2628
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 2632
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 2636
	beq $a1, $v1, isTopCollusionPixel
	addi $a1, $t0, 2640
	beq $a1, $v1, isTopCollusionPixel
	
	j notTopCollusionPixel
	
isTopCollusionPixel:
	addi $v1, $zero, 1
	j checkTopCollusionPixelReturn

notTopCollusionPixel:
	addi $v1, $zero, 0

checkTopCollusionPixelReturn:
	lw $a1 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

# Top Part of the Ship (Side)
checkTopCollusion:
	# $a0 - obs address
	# $a2 - obs pixel offset

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a2, 0($sp)			# Push return addres onto the stack.

	addi $a2, $zero, 2560
	jal checkTopCollusionPixel
	beq $v1, 1, isTopCollided
	
	addi $a2, $zero, 3076
	jal checkTopCollusionPixel
	beq $v1, 1, isTopCollided
	
	addi $a2, $zero, 3592
	jal checkTopCollusionPixel
	beq $v1, 1, isTopCollided
	
	addi $a2, $zero, 3596
	jal checkTopCollusionPixel
	beq $v1, 1, isTopCollided
	
	addi $a2, $zero, 3600
	jal checkTopCollusionPixel
	beq $v1, 1, isTopCollided
	
	addi $a2, $zero, 3604
	jal checkTopCollusionPixel
	beq $v1, 1, isTopCollided
	
	addi $a2, $zero, 3096
	jal checkTopCollusionPixel
	beq $v1, 1, isTopCollided
	
	addi $a2, $zero, 2588
	jal checkTopCollusionPixel
	beq $v1, 1, isTopCollided
	
	j isNotTopCollided
	
isTopCollided:
	addi $v1, $zero, 1
	jal deduceHealth
	j checkTopCollusionReturn
	
isNotTopCollided:
	addi $v1, $zero, 0
	
checkTopCollusionReturn:
	lw $a2 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra
	
# Bottom Part of the Ship (Pixel)
checkBottomCollusionPixel:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a1, 0($sp)			# Push return addres onto the stack.
	
	add $v1, $a0, $a2		# $v1 stores a pixel of obstacle in $a0.
	
	addi $a1, $t0, 0
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 516
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 3080
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 3596
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 4112
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 5140
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 5144
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 4636
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 4640
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 4644
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 4136
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 4140
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 4144
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 3636
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 3640
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 3644
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 3648
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 3140
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 3144
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 2636
	beq $a1, $v1, isBottomCollusionPixel
	addi $a1, $t0, 2640
	beq $a1, $v1, isBottomCollusionPixel
	
	j notBottomCollusionPixel
	
isBottomCollusionPixel:
	addi $v1, $zero, 1
	j checkBottomCollusionPixelReturn

notBottomCollusionPixel:
	addi $v1, $zero, 0

checkBottomCollusionPixelReturn:
	lw $a1 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

# Bottom Part of the Ship (Side)
checkBottomCollusion:
	# $a0 - obs address
	# $a2 - obs pixel offset

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $a2, 0($sp)			# Push return addres onto the stack.

	addi $a2, $zero, 1024
	jal checkBottomCollusionPixel
	beq $v1, 1, isBottomCollided
	
	addi $a2, $zero, 516
	jal checkBottomCollusionPixel
	beq $v1, 1, isBottomCollided
	
	addi $a2, $zero, 8
	jal checkBottomCollusionPixel
	beq $v1, 1, isBottomCollided
	
	addi $a2, $zero, 12
	jal checkBottomCollusionPixel
	beq $v1, 1, isBottomCollided
	
	addi $a2, $zero, 16
	jal checkBottomCollusionPixel
	beq $v1, 1, isBottomCollided
	
	addi $a2, $zero, 20
	jal checkBottomCollusionPixel
	beq $v1, 1, isBottomCollided
	
	addi $a2, $zero, 536
	jal checkBottomCollusionPixel
	beq $v1, 1, isBottomCollided
	
	addi $a2, $zero, 1052
	jal checkBottomCollusionPixel
	beq $v1, 1, isBottomCollided
	
	j isNotBottomCollided
	
isBottomCollided:
	addi $v1, $zero, 1
	jal deduceHealth
	j checkBottomCollusionReturn
	
isNotBottomCollided:
	addi $v1, $zero, 0
	
checkBottomCollusionReturn:
	lw $a2 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	jr $ra

#=============================================================================================================================================================================
#=============================================================================================================================================================================
#============================================================================= Obstacle  Drawing =============================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
drawObstacle:

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.

	sw $a0, 8($a1)
	sw $a0, 12($a1)
	sw $a0, 16($a1)
	sw $a0, 20($a1)
	sw $a0, 516($a1)
	sw $a0, 520($a1)
	sw $a0, 524($a1)
	sw $a0, 528($a1)
	sw $a0, 532($a1)
	sw $a0, 536($a1)
	sw $a0, 1024($a1)
	sw $a0, 1028($a1)
	sw $a0, 1032($a1)
	sw $a0, 1036($a1)
	sw $a0, 1040($a1)
	sw $a0, 1044($a1)
	sw $a0, 1048($a1)
	sw $a0, 1052($a1)
	sw $a0, 1536($a1)
	sw $a0, 1540($a1)
	sw $a0, 1544($a1)
	sw $a0, 1548($a1)
	sw $a0, 1552($a1)
	sw $a0, 1556($a1)
	sw $a0, 1560($a1)
	sw $a0, 1564($a1)
	sw $a0, 2048($a1)
	sw $a0, 2052($a1)
	sw $a0, 2056($a1)
	sw $a0, 2060($a1)
	sw $a0, 2064($a1)
	sw $a0, 2068($a1)
	sw $a0, 2072($a1)
	sw $a0, 2076($a1)
	sw $a0, 2560($a1)
	sw $a0, 2564($a1)
	sw $a0, 2568($a1)
	sw $a0, 2572($a1)
	sw $a0, 2576($a1)
	sw $a0, 2580($a1)
	sw $a0, 2584($a1)
	sw $a0, 2588($a1)
	sw $a0, 3076($a1)
	sw $a0, 3080($a1)
	sw $a0, 3084($a1)
	sw $a0, 3088($a1)
	sw $a0, 3092($a1)
	sw $a0, 3096($a1)
	sw $a0, 3592($a1)
	sw $a0, 3596($a1)
	sw $a0, 3600($a1)
	sw $a0, 3604($a1)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	
	jr $ra
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#=============================================================================== Ship  Drawing ===============================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================

drawShip:
	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	# Light Gray Pixels
	sw $a0, 4($t0)
	sw $a0, 8($t0)
	sw $a0, 520($t0)
	sw $a0, 524($t0)
	sw $a0, 528($t0)
	sw $a0, 1036($t0)
	sw $a0, 1040($t0)
	sw $a0, 1044($t0)
	sw $a0, 1048($t0)
	sw $a0, 2060($t0)
	sw $a0, 2064($t0)
	sw $a0, 2068($t0)
	sw $a0, 2072($t0)
	sw $a0, 2076($t0)
	sw $a0, 2080($t0)
	sw $a0, 2084($t0)
	sw $a0, 2572($t0)
	sw $a0, 2576($t0)
	sw $a0, 2580($t0)
	sw $a0, 2584($t0)
	sw $a0, 2588($t0)
	sw $a0, 2592($t0)
	sw $a0, 2596($t0)
	sw $a0, 2600($t0)
	sw $a0, 2604($t0)
	sw $a0, 2608($t0)
	sw $a0, 2612($t0)
	sw $a0, 2616($t0)
	sw $a0, 2620($t0)
	sw $a0, 2624($t0)
	sw $a0, 2628($t0)
	sw $a0, 2632($t0)
	sw $a0, 2636($t0)
	sw $a0, 2640($t0)
	sw $a0, 3136($t0)
	sw $a0, 3140($t0)
	sw $a0, 3600($t0)
	sw $a0, 3604($t0)
	sw $a0, 3608($t0)
	sw $a0, 3612($t0)
	sw $a0, 3616($t0)
	sw $a0, 3620($t0)
	sw $a0, 3624($t0)
	sw $a0, 3628($t0)
	sw $a0, 3632($t0)
	sw $a0, 3636($t0)
	sw $a0, 3640($t0)
	sw $a0, 4116($t0)
	sw $a0, 4120($t0)
	sw $a0, 4124($t0)
	sw $a0, 4128($t0)
	sw $a0, 4132($t0)
	
	# White pixels
	sw $a1, 1580($t0)
	sw $a1, 1584($t0)
	sw $a1, 1588($t0)
	sw $a1, 1592($t0)
	sw $a1, 2096($t0)
	sw $a1, 2100($t0)
	sw $a1, 2104($t0)
	sw $a1, 2108($t0)

	# Dark Gray Pixels
	sw $a2, 0($t0)
	sw $a2, 12($t0)
	sw $a2, 16($t0)
	sw $a2, 516($t0)
	sw $a2, 532($t0)
	sw $a2, 536($t0)
	sw $a2, 1032($t0)
	sw $a2, 1052($t0)
	sw $a2, 1056($t0)
	sw $a2, 1548($t0)
	sw $a2, 1552($t0)
	sw $a2, 1556($t0)
	sw $a2, 1560($t0)
	sw $a2, 1564($t0)
	sw $a2, 1568($t0)
	sw $a2, 1572($t0)
	sw $a2, 1576($t0)
	sw $a2, 2056($t0)
	sw $a2, 2088($t0)
	sw $a2, 2092($t0)
	sw $a2, 2568($t0)
	sw $a2, 3080($t0)
	sw $a2, 3084($t0)
	sw $a2, 3088($t0)
	sw $a2, 3092($t0)
	sw $a2, 3096($t0)
	sw $a2, 3100($t0)
	sw $a2, 3104($t0)
	sw $a2, 3108($t0)
	sw $a2, 3112($t0)
	sw $a2, 3116($t0)
	sw $a2, 3120($t0)
	sw $a2, 3124($t0)
	sw $a2, 3128($t0)
	sw $a2, 3132($t0)
	sw $a2, 3144($t0)
	sw $a2, 3596($t0)
	sw $a2, 3644($t0)
	sw $a2, 3648($t0)
	sw $a2, 4112($t0)
	sw $a2, 4136($t0)
	sw $a2, 4140($t0)
	sw $a2, 4144($t0)
	sw $a2, 4628($t0)
	sw $a2, 4632($t0)
	sw $a2, 4636($t0)
	sw $a2, 4640($t0)
	sw $a2, 4644($t0)
	sw $a2, 5140($t0)
	sw $a2, 5144($t0)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.

	jr $ra
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#========================================================================= Health Indicators Drawing =========================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
	
drawHealth1:

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sw $a0, 26640($s5)
	sw $a0, 26644($s5)
	sw $a0, 26660($s5)
	sw $a0, 26664($s5)
	sw $a0, 27148($s5)
	sw $a0, 27152($s5)
	sw $a0, 27156($s5)
	sw $a0, 27160($s5)
	sw $a0, 27168($s5)
	sw $a0, 27172($s5)
	sw $a0, 27176($s5)
	sw $a0, 27180($s5)
	sw $a0, 27656($s5)
	sw $a0, 27660($s5)
	sw $a0, 27664($s5)
	sw $a0, 27668($s5)
	sw $a0, 27672($s5)
	sw $a0, 27676($s5)
	sw $a0, 27680($s5)
	sw $a0, 27684($s5)
	sw $a0, 27688($s5)
	sw $a0, 27692($s5)
	sw $a0, 27696($s5)
	sw $a0, 28168($s5)
	sw $a0, 28172($s5)
	sw $a0, 28176($s5)
	sw $a0, 28180($s5)
	sw $a0, 28184($s5)
	sw $a0, 28188($s5)
	sw $a0, 28192($s5)
	sw $a0, 28196($s5)
	sw $a0, 28200($s5)
	sw $a0, 28204($s5)
	sw $a0, 28208($s5)
	sw $a0, 28680($s5)
	sw $a0, 28684($s5)
	sw $a0, 28688($s5)
	sw $a0, 28692($s5)
	sw $a0, 28696($s5)
	sw $a0, 28700($s5)
	sw $a0, 28704($s5)
	sw $a0, 28708($s5)
	sw $a0, 28712($s5)
	sw $a0, 28716($s5)
	sw $a0, 28720($s5)
	sw $a0, 29196($s5)
	sw $a0, 29200($s5)
	sw $a0, 29204($s5)
	sw $a0, 29208($s5)
	sw $a0, 29212($s5)
	sw $a0, 29216($s5)
	sw $a0, 29220($s5)
	sw $a0, 29224($s5)
	sw $a0, 29228($s5)
	sw $a0, 29712($s5)
	sw $a0, 29716($s5)
	sw $a0, 29720($s5)
	sw $a0, 29724($s5)
	sw $a0, 29728($s5)
	sw $a0, 29732($s5)
	sw $a0, 29736($s5)
	sw $a0, 30228($s5)
	sw $a0, 30232($s5)
	sw $a0, 30236($s5)
	sw $a0, 30240($s5)
	sw $a0, 30244($s5)
	sw $a0, 30744($s5)
	sw $a0, 30748($s5)
	sw $a0, 30752($s5)
	sw $a0, 31260($s5)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	
	jr $ra
	
drawHealth2:

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sw $a0, 26688($s5)
	sw $a0, 26692($s5)
	sw $a0, 26708($s5)
	sw $a0, 26712($s5)
	sw $a0, 27196($s5)
	sw $a0, 27200($s5)
	sw $a0, 27204($s5)
	sw $a0, 27208($s5)
	sw $a0, 27216($s5)
	sw $a0, 27220($s5)
	sw $a0, 27224($s5)
	sw $a0, 27228($s5)
	sw $a0, 27704($s5)
	sw $a0, 27708($s5)
	sw $a0, 27712($s5)
	sw $a0, 27716($s5)
	sw $a0, 27720($s5)
	sw $a0, 27724($s5)
	sw $a0, 27728($s5)
	sw $a0, 27732($s5)
	sw $a0, 27736($s5)
	sw $a0, 27740($s5)
	sw $a0, 27744($s5)
	sw $a0, 28216($s5)
	sw $a0, 28220($s5)
	sw $a0, 28224($s5)
	sw $a0, 28228($s5)
	sw $a0, 28232($s5)
	sw $a0, 28236($s5)
	sw $a0, 28240($s5)
	sw $a0, 28244($s5)
	sw $a0, 28248($s5)
	sw $a0, 28252($s5)
	sw $a0, 28256($s5)
	sw $a0, 28728($s5)
	sw $a0, 28732($s5)
	sw $a0, 28736($s5)
	sw $a0, 28740($s5)
	sw $a0, 28744($s5)
	sw $a0, 28748($s5)
	sw $a0, 28752($s5)
	sw $a0, 28756($s5)
	sw $a0, 28760($s5)
	sw $a0, 28764($s5)
	sw $a0, 28768($s5)
	sw $a0, 29244($s5)
	sw $a0, 29248($s5)
	sw $a0, 29252($s5)
	sw $a0, 29256($s5)
	sw $a0, 29260($s5)
	sw $a0, 29264($s5)
	sw $a0, 29268($s5)
	sw $a0, 29272($s5)
	sw $a0, 29276($s5)
	sw $a0, 29760($s5)
	sw $a0, 29764($s5)
	sw $a0, 29768($s5)
	sw $a0, 29772($s5)
	sw $a0, 29776($s5)
	sw $a0, 29780($s5)
	sw $a0, 29784($s5)
	sw $a0, 30276($s5)
	sw $a0, 30280($s5)
	sw $a0, 30284($s5)
	sw $a0, 30288($s5)
	sw $a0, 30292($s5)
	sw $a0, 30792($s5)
	sw $a0, 30796($s5)
	sw $a0, 30800($s5)
	sw $a0, 31308($s5)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	
	jr $ra
	
drawHealth3:

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sw $a0, 26736($s5)
	sw $a0, 26740($s5)
	sw $a0, 26756($s5)
	sw $a0, 26760($s5)
	sw $a0, 27244($s5)
	sw $a0, 27248($s5)
	sw $a0, 27252($s5)
	sw $a0, 27256($s5)
	sw $a0, 27264($s5)
	sw $a0, 27268($s5)
	sw $a0, 27272($s5)
	sw $a0, 27276($s5)
	sw $a0, 27752($s5)
	sw $a0, 27756($s5)
	sw $a0, 27760($s5)
	sw $a0, 27764($s5)
	sw $a0, 27768($s5)
	sw $a0, 27772($s5)
	sw $a0, 27776($s5)
	sw $a0, 27780($s5)
	sw $a0, 27784($s5)
	sw $a0, 27788($s5)
	sw $a0, 27792($s5)
	sw $a0, 28264($s5)
	sw $a0, 28268($s5)
	sw $a0, 28272($s5)
	sw $a0, 28276($s5)
	sw $a0, 28280($s5)
	sw $a0, 28284($s5)
	sw $a0, 28288($s5)
	sw $a0, 28292($s5)
	sw $a0, 28296($s5)
	sw $a0, 28300($s5)
	sw $a0, 28304($s5)
	sw $a0, 28776($s5)
	sw $a0, 28780($s5)
	sw $a0, 28784($s5)
	sw $a0, 28788($s5)
	sw $a0, 28792($s5)
	sw $a0, 28796($s5)
	sw $a0, 28800($s5)
	sw $a0, 28804($s5)
	sw $a0, 28808($s5)
	sw $a0, 28812($s5)
	sw $a0, 28816($s5)
	sw $a0, 29292($s5)
	sw $a0, 29296($s5)
	sw $a0, 29300($s5)
	sw $a0, 29304($s5)
	sw $a0, 29308($s5)
	sw $a0, 29312($s5)
	sw $a0, 29316($s5)
	sw $a0, 29320($s5)
	sw $a0, 29324($s5)
	sw $a0, 29808($s5)
	sw $a0, 29812($s5)
	sw $a0, 29816($s5)
	sw $a0, 29820($s5)
	sw $a0, 29824($s5)
	sw $a0, 29828($s5)
	sw $a0, 29832($s5)
	sw $a0, 30324($s5)
	sw $a0, 30328($s5)
	sw $a0, 30332($s5)
	sw $a0, 30336($s5)
	sw $a0, 30340($s5)
	sw $a0, 30840($s5)
	sw $a0, 30844($s5)
	sw $a0, 30848($s5)
	sw $a0, 31356($s5)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	
	jr $ra
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#========================================================================= Laser Indicators Drawings =========================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
	
drawLaser1:

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sw $a0, 26812($s5)
	sw $a0, 27320($s5)
	sw $a0, 27324($s5)
	sw $a0, 27328($s5)
	sw $a0, 27828($s5)
	sw $a0, 27832($s5)
	sw $a0, 27836($s5)
	sw $a0, 27840($s5)
	sw $a0, 27844($s5)
	sw $a0, 28340($s5)
	sw $a0, 28344($s5)
	sw $a0, 28348($s5)
	sw $a0, 28352($s5)
	sw $a0, 28356($s5)
	sw $a0, 28852($s5)
	sw $a0, 28856($s5)
	sw $a0, 28860($s5)
	sw $a0, 28864($s5)
	sw $a0, 28868($s5)
	sw $a0, 29364($s5)
	sw $a0, 29368($s5)
	sw $a0, 29372($s5)
	sw $a0, 29376($s5)
	sw $a0, 29380($s5)
	sw $a0, 29876($s5)
	sw $a0, 29880($s5)
	sw $a0, 29884($s5)
	sw $a0, 29888($s5)
	sw $a0, 29892($s5)
	sw $a0, 30388($s5)
	sw $a0, 30392($s5)
	sw $a0, 30396($s5)
	sw $a0, 30400($s5)
	sw $a0, 30404($s5)
	sw $a0, 30904($s5)
	sw $a0, 30908($s5)
	sw $a0, 30912($s5)
	sw $a0, 31420($s5)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	
	jr $ra
	
drawLaser2:

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sw $a0, 26840($s5)
	sw $a0, 27348($s5)
	sw $a0, 27352($s5)
	sw $a0, 27356($s5)
	sw $a0, 27856($s5)
	sw $a0, 27860($s5)
	sw $a0, 27864($s5)
	sw $a0, 27868($s5)
	sw $a0, 27872($s5)
	sw $a0, 28368($s5)
	sw $a0, 28372($s5)
	sw $a0, 28376($s5)
	sw $a0, 28380($s5)
	sw $a0, 28384($s5)
	sw $a0, 28880($s5)
	sw $a0, 28884($s5)
	sw $a0, 28888($s5)
	sw $a0, 28892($s5)
	sw $a0, 28896($s5)
	sw $a0, 29392($s5)
	sw $a0, 29396($s5)
	sw $a0, 29400($s5)
	sw $a0, 29404($s5)
	sw $a0, 29408($s5)
	sw $a0, 29904($s5)
	sw $a0, 29908($s5)
	sw $a0, 29912($s5)
	sw $a0, 29916($s5)
	sw $a0, 29920($s5)
	sw $a0, 30416($s5)
	sw $a0, 30420($s5)
	sw $a0, 30424($s5)
	sw $a0, 30428($s5)
	sw $a0, 30432($s5)
	sw $a0, 30932($s5)
	sw $a0, 30936($s5)
	sw $a0, 30940($s5)
	sw $a0, 31448($s5)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	
	jr $ra
	
drawLaser3:

	addi $sp, $sp, -4		# Move stack pointer a word.
	sw $ra, 0($sp)			# Push return addres onto the stack.
	
	sw $a0, 26868($s5)
	sw $a0, 27376($s5)
	sw $a0, 27380($s5)
	sw $a0, 27384($s5)
	sw $a0, 27884($s5)
	sw $a0, 27888($s5)
	sw $a0, 27892($s5)
	sw $a0, 27896($s5)
	sw $a0, 27900($s5)
	sw $a0, 28396($s5)
	sw $a0, 28400($s5)
	sw $a0, 28404($s5)
	sw $a0, 28408($s5)
	sw $a0, 28412($s5)
	sw $a0, 28908($s5)
	sw $a0, 28912($s5)
	sw $a0, 28916($s5)
	sw $a0, 28920($s5)
	sw $a0, 28924($s5)
	sw $a0, 29420($s5)
	sw $a0, 29424($s5)
	sw $a0, 29428($s5)
	sw $a0, 29432($s5)
	sw $a0, 29436($s5)
	sw $a0, 29932($s5)
	sw $a0, 29936($s5)
	sw $a0, 29940($s5)
	sw $a0, 29944($s5)
	sw $a0, 29948($s5)
	sw $a0, 30444($s5)
	sw $a0, 30448($s5)
	sw $a0, 30452($s5)
	sw $a0, 30456($s5)
	sw $a0, 30460($s5)
	sw $a0, 30960($s5)
	sw $a0, 30964($s5)
	sw $a0, 30968($s5)
	sw $a0, 31476($s5)
	
	lw $ra 0($sp)			# Pop return address from the stack.
	addi $sp, $sp, 4		# Move stack pointer a word.
	
	jr $ra
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#============================================================================= Game Over Drawing =============================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
	
drawGameOver:

	# G
	sw $a1, 11972($s5)
	sw $a1, 11976($s5)
	sw $a1, 11980($s5)
	sw $a1, 11984($s5)
	sw $a1, 11988($s5)
	sw $a1, 12480($s5)
	sw $a1, 12484($s5)
	sw $a1, 12988($s5)
	sw $a1, 12992($s5)
	sw $a1, 13500($s5)
	sw $a1, 13504($s5)
	sw $a1, 13516($s5)
	sw $a1, 13520($s5)
	sw $a1, 13524($s5)
	sw $a1, 14012($s5)
	sw $a1, 14016($s5)
	sw $a1, 14032($s5)
	sw $a1, 14036($s5)
	sw $a1, 14528($s5)
	sw $a1, 14532($s5)
	sw $a1, 14544($s5)
	sw $a1, 14548($s5)
	sw $a1, 15044($s5)
	sw $a1, 15048($s5)
	sw $a1, 15052($s5)
	sw $a1, 15056($s5)
	sw $a1, 15060($s5)

	# A
	sw $a1, 12008($s5)
	sw $a1, 12012($s5)
	sw $a1, 12016($s5)
	sw $a1, 12516($s5)
	sw $a1, 12520($s5)
	sw $a1, 12528($s5)
	sw $a1, 12532($s5)
	sw $a1, 13024($s5)
	sw $a1, 13028($s5)
	sw $a1, 13044($s5)
	sw $a1, 13048($s5)
	sw $a1, 13536($s5)
	sw $a1, 13540($s5)
	sw $a1, 13556($s5)
	sw $a1, 13560($s5)
	sw $a1, 14048($s5)
	sw $a1, 14052($s5)
	sw $a1, 14056($s5)
	sw $a1, 14060($s5)
	sw $a1, 14064($s5)
	sw $a1, 14068($s5)
	sw $a1, 14072($s5)
	sw $a1, 14560($s5)
	sw $a1, 14564($s5)
	sw $a1, 14580($s5)
	sw $a1, 14584($s5)
	sw $a1, 15072($s5)
	sw $a1, 15076($s5)
	sw $a1, 15092($s5)
	sw $a1, 15096($s5)

	# M 
	sw $a1, 12036($s5)
	sw $a1, 12040($s5)
	sw $a1, 12056($s5)
	sw $a1, 12060($s5)
	sw $a1, 12548($s5)
	sw $a1, 12552($s5)
	sw $a1, 12556($s5)
	sw $a1, 12564($s5)
	sw $a1, 12568($s5)
	sw $a1, 12572($s5)
	sw $a1, 13060($s5)
	sw $a1, 13064($s5)
	sw $a1, 13068($s5)
	sw $a1, 13072($s5)
	sw $a1, 13076($s5)
	sw $a1, 13080($s5)
	sw $a1, 13084($s5)
	sw $a1, 13572($s5)
	sw $a1, 13576($s5)
	sw $a1, 13580($s5)
	sw $a1, 13584($s5)
	sw $a1, 13588($s5)
	sw $a1, 13592($s5)
	sw $a1, 13596($s5)
	sw $a1, 14084($s5)
	sw $a1, 14088($s5)
	sw $a1, 14096($s5)
	sw $a1, 14104($s5)
	sw $a1, 14108($s5)
	sw $a1, 14596($s5)
	sw $a1, 14600($s5)
	sw $a1, 14616($s5)
	sw $a1, 14620($s5)
	sw $a1, 15108($s5)
	sw $a1, 15112($s5)
	sw $a1, 15128($s5)
	sw $a1, 15132($s5)

	# E
	sw $a1, 12072($s5)
	sw $a1, 12076($s5)
	sw $a1, 12080($s5)
	sw $a1, 12084($s5)
	sw $a1, 12088($s5)
	sw $a1, 12092($s5)
	sw $a1, 12096($s5)
	sw $a1, 12584($s5)
	sw $a1, 12588($s5)
	sw $a1, 13096($s5)
	sw $a1, 13100($s5)
	sw $a1, 13608($s5)
	sw $a1, 13612($s5)
	sw $a1, 13616($s5)
	sw $a1, 13620($s5)
	sw $a1, 13624($s5)
	sw $a1, 13628($s5)
	sw $a1, 14120($s5)
	sw $a1, 14124($s5)
	sw $a1, 14632($s5)
	sw $a1, 14636($s5)
	sw $a1, 15144($s5)
	sw $a1, 15148($s5)
	sw $a1, 15152($s5)
	sw $a1, 15156($s5)
	sw $a1, 15160($s5)
	sw $a1, 15164($s5)
	sw $a1, 15168($s5)

	# O
	sw $a1, 17600($s5)
	sw $a1, 17604($s5)
	sw $a1, 17608($s5)
	sw $a1, 17612($s5)
	sw $a1, 17616($s5)
	sw $a1, 18108($s5)
	sw $a1, 18112($s5)
	sw $a1, 18128($s5)
	sw $a1, 18132($s5)
	sw $a1, 18620($s5)
	sw $a1, 18624($s5)
	sw $a1, 18640($s5)
	sw $a1, 18644($s5)
	sw $a1, 19132($s5)
	sw $a1, 19136($s5)
	sw $a1, 19152($s5)
	sw $a1, 19156($s5)
	sw $a1, 19644($s5)
	sw $a1, 19648($s5)
	sw $a1, 19664($s5)
	sw $a1, 19668($s5)
	sw $a1, 20156($s5)
	sw $a1, 20160($s5)
	sw $a1, 20176($s5)
	sw $a1, 20180($s5)
	sw $a1, 20672($s5)
	sw $a1, 20676($s5)
	sw $a1, 20680($s5)
	sw $a1, 20684($s5)
	sw $a1, 20688($s5)
	
	# V
	sw $a1, 17632($s5)
	sw $a1, 17636($s5)
	sw $a1, 17652($s5)
	sw $a1, 17656($s5)
	sw $a1, 18144($s5)
	sw $a1, 18148($s5)
	sw $a1, 18164($s5)
	sw $a1, 18168($s5)
	sw $a1, 18656($s5)
	sw $a1, 18660($s5)
	sw $a1, 18676($s5)
	sw $a1, 18680($s5)
	sw $a1, 19168($s5)
	sw $a1, 19172($s5)
	sw $a1, 19176($s5)
	sw $a1, 19184($s5)
	sw $a1, 19188($s5)
	sw $a1, 19192($s5)
	sw $a1, 19684($s5)
	sw $a1, 19688($s5)
	sw $a1, 19692($s5)
	sw $a1, 19696($s5)
	sw $a1, 19700($s5)
	sw $a1, 20200($s5)
	sw $a1, 20204($s5)
	sw $a1, 20208($s5)
	sw $a1, 20716($s5)

	# E
	sw $a1, 17668($s5)
	sw $a1, 17672($s5)
	sw $a1, 17676($s5)
	sw $a1, 17680($s5)
	sw $a1, 17684($s5)
	sw $a1, 17688($s5)
	sw $a1, 17692($s5)
	sw $a1, 18180($s5)
	sw $a1, 18184($s5)
	sw $a1, 18692($s5)
	sw $a1, 18696($s5)
	sw $a1, 19204($s5)
	sw $a1, 19208($s5)
	sw $a1, 19212($s5)
	sw $a1, 19216($s5)
	sw $a1, 19220($s5)
	sw $a1, 19224($s5)
	sw $a1, 19716($s5)
	sw $a1, 19720($s5)
	sw $a1, 20228($s5)
	sw $a1, 20232($s5)
	sw $a1, 20740($s5)
	sw $a1, 20744($s5)
	sw $a1, 20748($s5)
	sw $a1, 20752($s5)
	sw $a1, 20756($s5)
	sw $a1, 20760($s5)
	sw $a1, 20764($s5)

	# R
	sw $a1, 17704($s5)
	sw $a1, 17708($s5)
	sw $a1, 17712($s5)
	sw $a1, 17716($s5)
	sw $a1, 17720($s5)
	sw $a1, 17724($s5)
	sw $a1, 18216($s5)
	sw $a1, 18220($s5)
	sw $a1, 18236($s5)
	sw $a1, 18240($s5)
	sw $a1, 18728($s5)
	sw $a1, 18732($s5)
	sw $a1, 18748($s5)
	sw $a1, 18752($s5)
	sw $a1, 19240($s5)
	sw $a1, 19244($s5)
	sw $a1, 19256($s5)
	sw $a1, 19260($s5)
	sw $a1, 19264($s5)
	sw $a1, 19752($s5)
	sw $a1, 19756($s5)
	sw $a1, 19760($s5)
	sw $a1, 19764($s5)
	sw $a1, 19768($s5)
	sw $a1, 20264($s5)
	sw $a1, 20268($s5)
	sw $a1, 20276($s5)
	sw $a1, 20280($s5)
	sw $a1, 20284($s5)
	sw $a1, 20776($s5)
	sw $a1, 20780($s5)
	sw $a1, 20792($s5)
	sw $a1, 20796($s5)
	sw $a1, 20800($s5)

	# P 
	sw $a1, 22184($s5)
	sw $a1, 22188($s5)
	sw $a1, 22192($s5)
	sw $a1, 22696($s5)
	sw $a1, 22704($s5)
	sw $a1, 23208($s5)
	sw $a1, 23212($s5)
	sw $a1, 23216($s5)
	sw $a1, 23720($s5)
	sw $a1, 24232($s5)

	# F 
	sw $a1, 22204($s5)
	sw $a1, 22208($s5)
	sw $a1, 22212($s5)
	sw $a1, 22716($s5)
	sw $a1, 23228($s5)
	sw $s1, 23232($s5)
	sw $a1, 23740($s5)
	sw $a1, 24252($s5)
	
	# O
	sw $a1, 22220($s5)
	sw $a1, 22224($s5)
	sw $a1, 22228($s5)
	sw $a1, 22732($s5)
	sw $a1, 22740($s5)
	sw $a1, 23244($s5)
	sw $a1, 23252($s5)
	sw $a1, 23756($s5)
	sw $a1, 23764($s5)
	sw $a1, 24268($s5)
	sw $a1, 24272($s5)
	sw $a1, 24276($s5)

	# R
	sw $a1, 22236($s5)
	sw $a1, 22240($s5)
	sw $a1, 22748($s5)
	sw $a1, 22756($s5)
	sw $a1, 23260($s5)
	sw $a1, 23264($s5)
	sw $a1, 23772($s5)
	sw $a1, 23780($s5)
	sw $a1, 24284($s5)
	sw $a1, 24292($s5)
	
	# R
	sw $a1, 22256($s5)
	sw $a1, 22260($s5)
	sw $a1, 22768($s5)
	sw $a1, 22776($s5)
	sw $a1, 23280($s5)
	sw $a1, 23284($s5)
	sw $a1, 23792($s5)
	sw $a1, 23800($s5)
	sw $a1, 24304($s5)
	sw $a1, 24312($s5)

	# E
	sw $a1, 22272($s5)
	sw $a1, 22276($s5)
	sw $a1, 22280($s5)
	sw $a1, 22784($s5)
	sw $a1, 23296($s5)
	sw $a1, 23300($s5)
	sw $a1, 23808($s5)
	sw $a1, 24320($s5)
	sw $a1, 24324($s5)
	sw $a1, 24328($s5)

	# S
	sw $a1, 22288($s5)
	sw $a1, 22292($s5)
	sw $a1, 22296($s5)
	sw $a1, 22800($s5)
	sw $a1, 23312($s5)
	sw $a1, 23316($s5)
	sw $a1, 23320($s5)
	sw $a1, 23832($s5)
	sw $a1, 24336($s5)
	sw $a1, 24340($s5)
	sw $a1, 24344($s5)

	# T
	sw $a1, 22304($s5)
	sw $a1, 22308($s5)
	sw $a1, 22312($s5)
	sw $a1, 22820($s5)
	sw $a1, 23332($s5)
	sw $a1, 23844($s5)
	sw $a1, 24356($s5)
	
	# A
	sw $a1, 22324($s5)
	sw $a1, 22832($s5)
	sw $a1, 22840($s5)
	sw $a1, 23344($s5)
	sw $a1, 23352($s5)
	sw $a1, 23856($s5)
	sw $a1, 23860($s5)
	sw $a1, 23864($s5)
	sw $a1, 24368($s5)
	sw $a1, 24376($s5)

	# R
	sw $a1, 22336($s5)
	sw $a1, 22340($s5)
	sw $a1, 22848($s5)
	sw $a1, 22856($s5)
	sw $a1, 23360($s5)
	sw $a1, 23364($s5)
	sw $a1, 23872($s5)
	sw $a1, 23880($s5)
	sw $a1, 24384($s5)
	sw $a1, 24392($s5)
	
	# T
	sw $a1, 22352($s5)
	sw $a1, 22356($s5)
	sw $a1, 22360($s5)
	sw $a1, 22868($s5)
	sw $a1, 23380($s5)
	sw $a1, 23892($s5)
	sw $a1, 24404($s5)
	
	#==============================
	
	# Q
	sw $a1, 25256($s5)
	sw $a1, 25260($s5)
	sw $a1, 25264($s5)
	sw $a1, 25768($s5)
	sw $a1, 25776($s5)
	sw $a1, 26280($s5)
	sw $a1, 26288($s5)
	sw $a1, 26792($s5)
	sw $a1, 26796($s5)
	sw $a1, 27312($s5)
	
	# F
	sw $a1, 25276($s5)
	sw $a1, 25280($s5)
	sw $a1, 25284($s5)
	sw $a1, 25788($s5)
	sw $a1, 26300($s5)
	sw $a1, 26304($s5)
	sw $a1, 26812($s5)
	sw $a1, 27324($s5)
	
	# O
	sw $a1, 25292($s5)
	sw $a1, 25296($s5)
	sw $a1, 25300($s5)
	sw $a1, 25804($s5)
	sw $a1, 25812($s5)
	sw $a1, 26316($s5)
	sw $a1, 26324($s5)
	sw $a1, 26828($s5)
	sw $a1, 26836($s5)
	sw $a1, 27340($s5)
	sw $a1, 27344($s5)
	sw $a1, 27348($s5)

	# R
	sw $a1, 25308($s5)
	sw $a1, 25312($s5)
	sw $a1, 25820($s5)
	sw $a1, 25828($s5)
	sw $a1, 26332($s5)
	sw $a1, 26336($s5)
	sw $a1, 26844($s5)
	sw $a1, 26852($s5)
	sw $a1, 27356($s5)
	sw $a1, 27364($s5)
	
	# Q
	sw $a1, 25328($s5)
	sw $a1, 25332($s5)
	sw $a1, 25336($s5)
	sw $a1, 25840($s5)
	sw $a1, 25848($s5)
	sw $a1, 26352($s5)
	sw $a1, 26360($s5)
	sw $a1, 26864($s5)
	sw $a1, 26868($s5)
	sw $a1, 27384($s5)

	# U
	sw $a1, 25344($s5)
	sw $a1, 25352($s5)
	sw $a1, 25856($s5)
	sw $a1, 25864($s5)
	sw $a1, 26368($s5)
	sw $a1, 26376($s5)
	sw $a1, 26880($s5)
	sw $a1, 26888($s5)
	sw $a1, 27392($s5)
	sw $a1, 27396($s5)
	sw $a1, 27400($s5)
	
	# I
	sw $a1, 25360($s5)
	sw $a1, 25872($s5)
	sw $a1, 26384($s5)
	sw $a1, 26896($s5)
	sw $a1, 27408($s5)

	# T
	sw $a1, 25368($s5)
	sw $a1, 25372($s5)
	sw $a1, 25376($s5)
	sw $a1, 25884($s5)
	sw $a1, 26396($s5)
	sw $a1, 26908($s5)
	sw $a1, 27420($s5)
	
	jr $ra
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#============================================================================= Game Over Screen ==============================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================

gameOver:
	jal clearScreen			# Clears the screen

	lw $s5, textAddr
	lw $a1, white			# Set Game Over text color to white.
	jal drawGameOver		# Draw game over screen.
	
	lw $t9, keyLocation

waitGameOverKey:

	lw $a0, 0($t9)			# Check Key event.
	bne $a0, 1, waitGameOverKey	# If no keyboard event, start again.
	
	lw $a0, 4($t9) 
	
	beq $a0, 80, START		# If keypress is 'p', branch to START (Restart Condition).
	beq $a0, 112, START		# If keypress is 'p', branch to START (Restart Condition).
	beq $a0, 81, Exit		# Else if keypress is 'q', branch to Exit (End Condition).
	beq $a0, 113, Exit		# Else if keypress is 'q', branch to Exit (End Condition).
	
	j waitGameOverKey		# LOOP.
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#=============================================================================== Clear Screen ================================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
	
clearScreen:
	lw $a0, textAddr		# $a0 is an iterator, initially screen address.
	addi $s5, $a0, 32764		# $s5 stores screen address + 32764 (bottom-right pixel).
	lw $s4, black
	
clearScreenLoop:
	beq $s5, $a0, cleaned		# If the bottom-right pixel is reached, then the cleaning is done, jump to start of the game.
	sw $s4, ($a0)			# Make the corresponding pixel black.
	addi $a0, $a0, 4		# Increase iterator.
	j clearScreenLoop		# LOOP.
	
cleaned:
	jr $ra
	
#=============================================================================================================================================================================
#=============================================================================================================================================================================
#==================================================================================== EXIT ===================================================================================
#=============================================================================================================================================================================
#=============================================================================================================================================================================
	
Exit:
	li $v0, 10 			# terminate the program
	syscall
