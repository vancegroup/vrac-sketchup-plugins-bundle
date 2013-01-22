=begin
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Designed Dec. 2009 by Fredo6

# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name			:  Lib6Operation.rb
# Original Date	:  03 Dec 2009 - version 1.0
# Type			:  Script library part of the LibFredo6 shared libraries
# Description	:  Class to manage construction of geometry via Sketchup Operation
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
=end

#---------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------
# Class SUOperation: Manage Sketchup Operations
#---------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------

module Traductor

#Messages and Label for VCB
T6[:T_MSG_Abort] = "Do you want to abort operation?"
T6[:T_MSG_AbortLeave] = "Do you want to finish operation before leaving the tool?"
T6[:T_LABEL_Wait] = "WAIT"
T6[:T_LABEL_Finishing] = "Finishing"

#Tooltip message
T6[:T_TIP_Computing] = "COMPUTING"
T6[:T_TIP_Interrupt] = "Click anywhere or Escape to interrupt the operation"
T6[:T_TIP_Aborted] = "ABORTED by user"
T6[:T_TIP_Time] = "Time: %1 second"

class SUOperation

#---------------------------------------------------------------------
# Class methods
#---------------------------------------------------------------------

@@last_suops = nil

#Start an embedded operation
def SUOperation.embedded_start_operation(title, speedup=false)
	if @@last_suops
		real, fake = @@last_suops.get_operation_status
		return if real
	end
	G6.start_operation(Sketchup.active_model, title, speedup)
end

#Commit an embedded operation
def SUOperation.embedded_commit_operation
	if @@last_suops
		real, fake = @@last_suops.get_operation_status
		return if real
	end
	
	Sketchup.active_model.commit_operation
	
	if @@last_suops && fake
		@@last_suops.start_operation_fake @@last_suops.get_last_title
	end	
end

#Forget an embedded operation
#CAUTION: geometry created within the embedded operation must be undone manually before
def SUOperation.embedded_forget_operation
	if @@last_suops
		real, fake = @@last_suops.get_operation_status
		return if real
	end
	
	Sketchup.active_model.abort_operation
	
	if @@last_suops && fake
		@@last_suops.start_operation_fake @@last_suops.get_last_title
	end	
end

#---------------------------------------------------------------------
# Instance methods
#---------------------------------------------------------------------

#Initialization
def initialize(*hargs)
	@view = Sketchup.active_model.active_view
	@operation_real = false
	@operation_fake = false
	reset
	
	#Parsing the arguments
	hargs.each { |arg| arg.each { |key, value|  parse_args(key, value) } if arg.class == Hash }
		
	#Initialization message
	@msg_abort = T6[:T_MSG_Abort]
	@msg_abort_leave = T6[:T_MSG_AbortLeave]
	@label_wait = T6[:T_LABEL_Wait]
	@label_finishing = T6[:T_LABEL_Finishing]
	@tip_computing = T6[:T_TIP_Computing]
	@tip_interrupt = T6[:T_TIP_Interrupt]

	#Initializing the cursors
	@id_cursor_hourglass_green = Traductor.create_cursor "Cursor_hourGlass_Green", 16, 16	
	@id_cursor_hourglass_blue = Traductor.create_cursor "Cursor_hourGlass_Blue", 16, 16	
	@id_cursor_hourglass_red = Traductor.create_cursor "Cursor_hourGlass_Red", 16, 16		
end

def reset
	@running = false
	@ask_interrupt = false
	@reversible_interrupt = false
	@run_timer = nil
end

#Parse the arguments of the initialize method
def parse_args(key, value)
	skey = key.to_s
	case skey
	when /title/i
		@title = value
	when /palette/i
		@palette = value
	when /end_proc/i
		@end_proc = value
	when /no_commit/i
		@no_commit = value	
	end	
end	

#Define the end procedure of the caller
def define_end_proc(&end_proc)
	@end_proc = end_proc
end

#Compute the title of the operation	
def set_title(title)
	@title = title
end
	
#Get operation status
def get_operation_status
	[@operation_real, @operation_fake]
end	
#----------------------------------------------------------------------------------
# Basic operation management
#----------------------------------------------------------------------------------

#Commit the operation
def commit_operation
	@@last_suops = self
	if @operation_real
		status = Sketchup.active_model.commit_operation
		@operation_real = false
	end	
end

#Undo the operation	
def undo_operation
	commit_operation
	Sketchup.undo
end

#Abort the operation
def abort_operation
	@@last_suops = self
	if @operation_real
		Sketchup.active_model.abort_operation
		@operation_real = false
	end	
end

#Start the operation
def start_operation(title=nil)
	@@last_suops = self
	finish_operation
	G6.start_operation Sketchup.active_model, get_title(title), true
	@operation_real = true
end

#Start operation either in fake mode
def start_operation_fake(title=nil)
	@@last_suops = self
	unless @operation_fake
		@operation_fake = true
		@operation_real = false
		Sketchup.active_model.start_operation get_title(title)
	end	
end

#Reserved for SU7
def continue_operation(title=nil)
	G6.continue_operation Sketchup.active_model, get_title(title), true, false, true
	@operation_real = true
end

#Finish by Aborting fake operation or Committing true operation
def finish_operation
	@@last_suops = self
	if @operation_fake
		Sketchup.active_model.abort_operation
	end
	if @operation_real
		Sketchup.active_model.commit_operation
		@operation_real = false
	end	
	@operation_fake = false
end

#Compute the title of the operation	
def get_last_title ; @last_title ; end
def get_title(title=nil)
	@last_title = (title) ? title : ((@title) ? @title : "operation")
end
	
#---------------------------------------------------------------------------------------
# Management of Interruptable operations
#---------------------------------------------------------------------------------------
	
#Request interruption of the script. <reversible> indicate if the opration could or not be pursued after interruption
def interrupt?(reversible=true)
	return false unless @running
	@ask_interrupt = true
	@reversible_interrupt = reversible
end

#Interface to the main tool to know if the geometry creation is being executed
def running?
	@running
end

#Determine if this is time to give back control to the GUI and does it if so	
def yield?
	#Interruption requested
	if @ask_interrupt
		UI.stop_timer @run_timer if @run_timer
		@run_timer = nil
		@ask_interrupt = false
		aborting = false
		if @reversible_interrupt
			status = UI.messagebox @msg_abort, MB_YESNO 
			aborting = true if status == 6
		else
			status = UI.messagebox @msg_abort_leave, MB_YESNO 
			if status == 6
				@deltayield = 60
				return false
			else
				aborting = true
			end	
		end	
		if aborting
			abort_execution
			return true
		else
			@tyield = Time.now.to_f
		end	
	end	
	
	#Checking if time to yield to UI
	if Time.now.to_f - @tyield > @deltayield
		@tyield = Time.now.to_f
		@run_timer = UI.start_timer(0.05, false) { step_geometry }
		return true
	end

	false	
end

#Move to the next step
def next_step(*args)
	@param_action = args
	if args[0]
		return false
	end	
	terminate_execution
	true	
end

def countage
	@pbar.countage
	@i_tick += 1
end

def current_step
	@param_action
end
		
#Call back execution for a piece of geometry
def step_geometry
	@exec_proc.call if @exec_proc
end

#Launch the Execution of Geometry
def launch_execution(nb_ticks, title=nil, &exec_proc)
	@exec_proc = exec_proc
	@nb_ticks = nb_ticks
	@i_tick = 0
	@running = 1
	
	@deltayield = 2.0
	@run_timer = nil
	
	@pbar = Traductor::ProgressionBar.new nb_ticks, @tip_computing
	@tbeg = Time.now.to_f
	@tyield = @tbeg
	start_operation unless @operation_real
	
	#Setting the tooltips and message
	@view.tooltip = @tip_computing
	@palette.set_message @tip_interrupt, 'I' if @palette
	onSetCursor
	@view.invalidate

	@param_action = :_init
	
	step_geometry 
end

#Terminate the Geometry execution
def abort_execution ; terminate_execution true ; end
def terminate_execution(abort=false)
	UI.stop_timer @run_timer if @run_timer
	if abort
		abort_operation
		@time_calculation = -1
	else	
		commit_operation unless @no_commit
		@time_calculation = Time.now.to_f - @tbeg
	end	
	reset
	show_time_to_palette
	
	@end_proc.call(@time_calculation) if @end_proc
end

def indicate_wait
	@pbar.set_label @label_wait
	@running = 2
	onSetCursor
end

def indicate_finishing
	@pbar.set_label @label_finishing
	@running = 3
	onSetCursor
end

#Set the cursor depending on the state of execution
def onSetCursor
	case @running
	when 2
		ic = @id_cursor_hourglass_red
	when 3
		ic = @id_cursor_hourglass_blue
	when 1
		ic = @id_cursor_hourglass_green
	else
		return false
	end	
	UI::set_cursor(ic)
end

#Log the final time to palette if any
def show_time_to_palette
	return unless @palette
	if @time_calculation < 0
		mode = 'E'
		tooltip = T6[:T_TIP_Aborted]
	else
		tooltip = T6[:T_TIP_Time, sprintf("%4.2f", @time_calculation)]
		mode = 'W'
	end	
	@palette.set_message if @palette
	@palette.set_tooltip tooltip, mode
end

end	#End Class SUOperation

end	#End Module Traductor

