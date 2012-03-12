#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright © 2008 Fredo6 - Designed and written Jan-Feb 2008 by Fredo6
#
# Permission to use this software for any purpose and without fee is hereby granted
# Distribution of this software for commercial purpose is subject to:
#  - the expressed, written consent of the author
#  - the inclusion of the present copyright notice in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   JoinPushPull.rb
# Type		:   Sketchup Tool
# Description	:   push-pull of multiple faces but keeping all generated faces joined
#                                 Vector and Classic Push Pull also included in multi-face mode
# Menu Items	:   Tools --> "Joint Push Pull", "Vector Push Pull", "Normal Push Pull", "Start-Over Push Pull" and "Redo Push Pull"
# Context Menu	:   none
# Usage		:   See Tutorial in PDF format
# Original Date	:   20 Feb 2008
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

require 'sketchup.rb'
begin
	require 'libtraductor.rb'		# for language translation
rescue
end

module JointPushPull

@jpp_dir = File.dirname __FILE__

STR_MsgPB_Completion = ["Faces:",
                        "|FR| Faces:",
                        "|ES| Caras:",
                        "|IT| Facce:"]

STR_MsgNoSelection = ["You must select at least one face",
                      "|FR| Aucune face selectionn\ée",
                      "|ES| Antes debes Seleccionar al menos una Cara !!",
                      "|IT| Devi selezionare almeno una faccia"]

STR_MsgInvalidVector = ["Invalid Vector for requested Push Pull\nReset to FREE VECTOR",
                           "|FR| Vecteur invalide pour le Push pull demand\é\nRemise du vecteur libre",
                           "|ES| Vector Inválido para el Empujar-Tirar Solicitado\nSe Reiniciara a un VECTOR LIBRE !!",
                           "|IT| Vettore invalido per il Push Pull richiesto\nSeleziona un VETTORE LIBERO"]

STR_MsgInvalidProjection = ["Invalid Privileged Plane for requested Push Pull\nReset to NO PLANE",
                           "|FR| Plan privilegi\é invalide pour le Push pull demand\é\nSuppression du plan",
                           "|ES| Restricción de Plano Inválida para el Empujar-Tirar Requerido\nSe Reiniciara a NINGÚN PLANO !!",
                           "|IT| Piano privilegiato non Valido per il Push Pull richiesto\nResetta a NESSUN PIANO"]

STR_MsgDistanceZero = ["Distance is zero",
                       "|FR| La distance est \égale a z\éro",
                       "|ES| La Distancia es Cero !!",
                       "|IT| La distanza \è zero"]

STR_MsgNoRedo = ["No previous Push Pull operation to execute",
                 "|FR| Pas d'op\ération de Push Pull ex\écut\ée pr\éc\édemment",
                 "|ES| No hay una Operación Previa de Empujar-Tirar para Rehacer !!",
                 "|IT| Nessuna precedente oeprazione di Push Pull da eseguire"]

DLG_Title_J = ["Joint Push Pull",
			   "|FR| Push-Pull jointif",
			   "|ES| Empujar-Tirar Conjunto",
			   "|IT| Push Pull Congiunto"]

DLG_Title_V = ["Vector Push Pull",
			   "|FR| Push-Pull selon un vecteur",
			   "|ES| Empujar-Tirar Vector",
			   "|IT| Push Pull Vettoriale"]

DLG_Title_N = ["Normal Push Pull",
			   "|FR| Push-Pull Normal",
			   "|ES| Empujar-Tirar Normal",
			   "|IT| Push Pull Normale"]

DLG_MnuUndo = ["Undo Push Pull and reselect faces",
			   "|FR| Recommencer Push Pull et selection faces",
			   "|ES| Deshacer Empujar-Tirar y Re-Seleccionar Caras",
			   "|IT| Annulla Push Pull e reseleziona facce"]
DLG_TipUndo = ["Undo and start over with previous selection",
			   "|FR| Annule et reprend la s\élection initiale",
			   "|ES| Deshacer y Recuperar la Selección Original",
			   "|IT| Annulla e reinizia con la precedente selezione"]

DLG_MnuRedo = ["Redo Same Push Pull",
			   "|FR| R\é-ex\écuter le meme Push Pull",
			   "|ES| Rehacer Ultimo Empujar-Tirar",
			   "|IT| Rifai lo stesso Push Pull"]
DLG_TipRedo = ["Redo on current selection",
			   "|FR| R\é-ex\écuter sur la s\élection courante",
			   "|ES| Rehacer en la Selección Actual",
			   "|IT| Rifai con la selezione corrente"]

DLG_EnumYesNo = { 'Y' => "Yes |FR| Oui |ES| Si |IT| Si",
				  'N' => "No |FR| Non |ES| No |IT| No" }

DLG_EnumFinishing = {
                      'K' => ["Keep original faces",
                              "|FR| Conserver les faces d'origine",
                              "|ES| Mantener Caras Originales",
                              "|IT| Mantieni le facce originali"],
                      'R' => ["Thickening",
                              "|FR| Epaississement",
                              "|ES| Generar Espesor",
                              "|IT| Ispessimento"],
				      'D' => ["Erase original faces",
          				      "|FR| Effacer les faces d'origine",
          				      "|ES| Borrar Caras Originales",
          				      "|IT| Cancella le facce originali"],
     				}

DLG_InfoFinishing = {
                      'K' => ["KEEP FACES",
                              "|FR| CONSERVER FACES",
                              "|ES| MANTENER CARAS ORIGINALES",
                              "|IT| MANTIENI LE FACCE"],
                      'R' => ["THICKENING",
                              "|FR| EPAISSISSEMENT",
                              "|ES| GENERAR ESPESOR",
                              "|IT| ISPESSIMENTO"],
				      'D' => ["ERASE FACES",
          				      "|FR| EFFACER FACES",
          				      "|ES| BORRAR CARAS ORIGINALES",
          				      "|IT| CANCELLA FECCE"],
     				}

DLG_EnumBorders = 	{
                      'N' => ["NO borders",
                              "|FR| Pas de faces de bordure",
                              "|ES| Sin Bordes",
                              "|IT| NESSUN Bordo"],
                      'O' => ["Borders on outer faces only",
                              "|FR| Bordures sur les faces exterieures",
                              "|ES| Bordes solo en Caras Externas",
                              "|IT| Bordo solo per le facce esterne"],
				      'A' => ["Borders on ALL faces",
          				      "|FR| Bordures sur toutes les faces",
          				      "|ES| Bordes en Todas las Caras",
          				      "|IT| Bordo per TUTTE le facce"],
					}

DLG_InfoBorders = 	{
                      'N' => ["NO BORDER",
                              "|FR| PAS DE BORDURE",
                              "|ES| SIN BORDES",
                              "|IT| NESSUN BORDO"],
                      'O' => ["BORDER",
                              "|FR| BORDURES EXTERIEURES",
                              "|ES| CON BORDES",
                              "|IT| BORDO"],
				      'A' => ["BORDER ALL",
          				      "|FR| BORDURES PARTOUT",
          				      "|ES| BORDES EN TODO",
          				      "|IT| BORDI DAPPERTUTTO"],
					}

DLG_InfoGroup = ["GROUP", "|FR| GROUPE", "|ES| GRUPO", "|IT| GRUPPO"]
DLG_InfoInfluence = ["EXTEND INFLUENCE", "|FR| INFLUENCE EXTERNE", "|ES| EXTENDER INFLUENCIA", "|IT| ESTENDI INCIDENZA"]
DLG_InfoAngleInfluence = ["ANGLE INFLUENCE", "|FR| ANGLE INFLUENCE", "|ES| ANGULO DE INFLUENCIA", "|IT| ANGOLO DI INCIDENZA"]

MSG_MnuOption = ["Additional Options (TAB)",
                 "|FR| Options suppl\émentaires (TAB)",
                 "|ES| Opciones Adicionales (Tecla TAB)",
                 "|IT| Ulteriori opzioni (TAB)"]
MSG_MnuDone = "Done |FR| Termin\é |ES| Terminar |IT| FATTO"

MSG_MnuPP = [ "Privileged Plane", "|FR| Plan Privilegi\é", "|ES| Restricción de Plano", "|IT| Piano privilegiato"]
MSG_MnuPPNone = [ "None (Ctrl-DOWN)", "|FR| Aucun (Ctrl-DOWN)", "|ES| Ninguna (Ctrl-ABAJO)", "|IT| Nessuno (CTRL+Gi\ù)"]
MSG_MnuPPBlue = [ "Blue (Ctrl-UP)", "|FR| Bleu (Ctrl-UP)", "|ES| Azul (Ctrl-ARRIBA)", "|IT| Blu (CTRL+SU)"]
MSG_MnuPPRed = [ "Red (Ctrl-RIGHT)", "|FR| Rouge (Ctrl-DROITE)", "|ES| Rojo (Ctrl-DERECHA)", "|IT| Rosso (CTRL+DESTRA)"]
MSG_MnuPPGreen = [ "Green (Ctrl-LEFT)", "|FR| Vert (Ctrl-GAUCHE)", "|ES| Verde (Ctrl-IZQUIERDA)", "|IT| Verde (CTRL+SINISTRA)"]
MSG_MnuPPCustom = [ "Custom (Ctrl alone)", "|FR| Personalis\é (Ctrl seul)", "|ES| Personalizada (Solo Ctrl)", "|IT| Custom (CTRL)"]
MSG_MnuFinishing = [ "Finishing", "|FR| Traitement faces", "|ES| Refinamiento", "|IT| Esegui"]
MSG_MnuBorders = [ "Borders", "|FR| Bordure ", "|ES| Bordes ", "|IT| Bordi"]
MSG_MnuGroup = [ "Generate as Group", "|FR| G\én\érer comme Groupe", "|ES| Crear como Grupo", "|IT| Genera come Gruppo"]
MSG_MnuExtended = [ "Extend Influence", "|FR| Etendre Influence", "|ES| Extender Influencia", "|IT| Estendi Incidenza"]
MSG_MnuAngle = [ "Toggle Angle Influence", "|FR| Bascule Angle Influence", "|ES| Alternar Angulo de Influencia", "|IT| Alterna angolo di incidenza"]
MSG_MnuCurrent = [ "(current = ", "|FR| (courant = ", "|ES| (Actualmente = ", "|IT| (corrente = "]

DLG_Distance = ["Distance",
                "|FR| Distance",
                "|ES| Distancia",
                "|IT| Distanza"]

DLG_KeepAsGroup = ["Generate as a Group",
                   "|FR| G\én\érer dans un groupe",
                   "|ES| Crear como Grupo",
                   "|IT| Genera come Gruppo"]

DLG_Finishing = ["Finishing options",
                 "|FR| Finalisation",
                 "|ES| Opciones de Refinamiento",
                 "|IT| Opzioni di finalizzazione"]

DLG_Extended = ["Extend influence to non-selected neighbors",
                "|FR| Etendre influence aux voisins non selectionn\és",
                "|ES| Extender Influencia de Caras No Seleccionadas Vecinas",
                "|IT| Estendi incidenza ai vicini non selezionati"]

DLG_Borders = ["Create border faces",
               "|FR| Cr\éer les faces de bordure",
               "|ES| Crear Caras en Bordes",
               "|IT| Crea facce del bordo"]

DLG_AngleInfluence = ["Angle of influence (degree)",
                      "|FR| Angle d'influence (degr\é)",
                      "|ES| Angulo de Influencia (Grados)",
                      "|IT| Angolo di incidenza (Gradi)"]

DLG_PressTab = ["Press TAB to change",
                "|FR| TAB pour changer",
                "|ES| Presiona TAB para Cambiar",
                "|IT| Premi TAB per cambiare"]

#Strings for the Selector Tool

MSG_Distance = "Distance |FR| Distance |ES| Distancia |IT| Distanza"
MSG_Vector_Origin = ["Select Origin of Vector",
                    "|FR| S\électionner l'origine du vecteur",
                    "|ES| Especifica el Origen del Vector",
                    "|IT| Seleziona l'origine del Vettore"]
MSG_Vector_End = ["Select End of Vector",
                 "|FR| S\électionner l'extremit\é du vecteur",
                 "|ES| Especifica el Final del Vector",
                 "|IT| Seleziona la fine del Vettore"]
MSG_Face_Origin = ["Select a Face",
                    "|FR| S\électionner une face",
                    "|ES| Selecciona una Cara",
                    "|IT| Seleziona una Faccia"]
MSG_Face_End = ["Drag selected face",
                 "|FR| Pousser / Tirer la face",
                 "|ES| Empuja o Tira de la Cara",
                 "|IT| Sposta la faccia selezionata"]
MSG_Input_Execution = ["Double Click or Enter to launch",
                    "|FR| Double cliquez ou Enter pour ex\écuter",
                    "|ES| Doble Clic o Enter para Terminar",
                    "|IT| Doppio Clik o Invio per eseguire"]

#Strings for the Plane Selector tools

MSG_Degree = "Degree |FR| Degr\é |ES| Grados |IT| Gradi"
MSG_PlaneAngle = "Plane Angle |FR| Angle du plan |ES| Angulo del Plano |IT| Angolo del Piano"
MSG_Input_Origin = ["Select Origin and Plane (Shift to lock plane)",
                    "|FR| S\électionner l'origine et le plan (Maj pour verrouiller le plan)",
                    "|ES| Especifica el Origen y el Plano de Restricción (Mantén Shift para Bloquear el Plano)",
                    "|IT| Seleziona origine e il piano (SHIFT per bloccare il piano)"]
MSG_Finish_Plane = ["Double Click or Enter when done (or adjust angle value in VCB)",
                    "|FR| Double cliquez ou press Enter pour fnir (ou valeur de l'angle dans la VCB)",
                    "|ES| Doble Clic o Enter para Definir Restricción (o Ajusta el Valor del Angulo en el Cuadro de Medidas)",
                    "|IT| Doppio click o Invio alla fine (oppure regola il valore dell'angolo in VCB"]

#Constants for Joint Push Pull Module (do not translate)	
STATE_V_ORIGIN = 0
STATE_V_END = 1
STATE_V_EXECUTION = 2

STATE_P_ORIGIN = 0
STATE_P_EXECUTION = 1

MAX_VISUAL_FACES = 1000

NULT_TOOLBAR = "Joint Push Pull"

SU_MAJOR_VERSION_6 = (Sketchup.version[0..0] > '5')	
JPP___Finishing = 116	#F5 - Finishing options			   
JPP___Borders = 117		#F6 - Borders options			   
JPP___Group = 118		#F7 - Group  option			   
JPP___Extended = 119	#F8 - Extended  option			   
JPP___Angle = 120		#F9 - Angle  option	

JPP_ERROR_InvalidParameters =	1
JPP_ERROR_NoValidFaces =	2
JPP_ERROR_InvalidDistance =	3
JPP_ERROR_InvalidVector	=	4
JPP_ERROR_FailedExecution =	5
JPP_ERROR_InvalidSelection =	5
JPP_ERROR_OtherError =		99

#--------------------------------------------------------------------------------------------------------------
# External API to Push Pull (can be called by extrenal scripts)
#--------------------------------------------------------------------------------------------------------------			 				   
	   
def JointPushPull.Api_call (type="J", selection=nil, distance=0, vector=nil, finishing='K', borders='A', 
						    group=true, influence=true, angle=30.0)

	begin
		#checking type of push pull
		type = type.upcase
		type = 'J' unless type == 'V' || type == 'N' || type == 'J'
		jpp = JPP.new type

		#checking faces
		selection = Sketchup.active_model.selection unless selection
		@lst_faces = []
		selection.each { |e| @lst_faces.push e if (e.class == Sketchup::Face) }
		return JPP_ERROR_NoValidFaces if (@lst_faces.length == 0)

		#checking distance
		distance = distance.to_l
		return JPP_ERROR_InvalidDistance if distance == 0
		
		#checking vector of direction
		return JPP_ERROR_InvalidVector unless (vector && vector.valid?) if type == 'V'
		vector = nil if type == 'N'
		
		#Other options
		finishing = 'K' unless finishing && (finishing == 'D' || finishing == 'R' || finishing == 'K')
		borders = 'A' unless borders && (borders == 'N' || borders == 'O' || borders == 'A')
		borders = 'O' if (borders == 'A' && type != 'N')
		angle = 75.0 if angle > 75.0
		angle = 0.0 if angle < 0.0
		angle = angle.degrees if type == 'J'
		
		#creating the Push Pull class
		jpp = JPP.new type
		jpp.api_call selection, distance, vector, finishing, borders, group, influence, angle
		
	#other execution errors
	rescue
		return JPP_ERROR_OtherError
	end
	
	return 0
end
   
def JointPushPull.get_file(name)
	return nil unless name
	f = File.join @jpp_dir, name
	FileTest.exist?(f) ? f : nil
end

#--------------------------------------------------------------------------------------------------------------
# Top Calling function: create each class once, and reuse them for subsequent calls
#--------------------------------------------------------------------------------------------------------------			 				   
def JointPushPull.execute(type)
	Sketchup.active_model.select_tool nil
	if type == 'V'
		@jppclass_v = JPP.new 'V' unless @jppclass_v
		@jppclass_v.start_input
	elsif type == 'N'
		@jppclass_n = JPP.new 'N' unless @jppclass_n
		@jppclass_n.start_input
	else
		@jppclass_j = JPP.new 'J' unless @jppclass_j
		@jppclass_j.start_input
	end	
end
	
def JointPushPull.undo
	return UI.beep unless @jppclass && JointPushPull.same_entities?
	Sketchup.undo
	JointPushPull.reselect_faces
end

def JointPushPull.same_entities?
	lst = Sketchup.active_model.active_entities
	return false unless (@saved_entities || lst.length != @saved_entities.length)
	lst.each_with_index do |e, i|
		return false if e != @saved_entities[i]
	end
	true
end

def JointPushPull.reselect_faces
	lstnewfaces = []
	Sketchup.active_model.active_entities.each do |e|
		if (e.class == Sketchup::Face) && ((! @saved_entities.include? e) || (@list_faces.include? e))
			lstnewfaces.push e
		end
	end	
	if (lstnewfaces.length > 0)	
		if (lstnewfaces.length != @list_faces.length)	#A non selected face was incidentally created by undo
			facestokeep = []
			lstnewfaces.each { |f| facestokeep.push f if (@list_centers.include? f.bounds.center) }
			lstnewfaces = facestokeep
		end
		Sketchup.active_model.selection.clear
		Sketchup.active_model.selection.add lstnewfaces
	else	
		lstnewfaces = @list_faces
	end	
	Sketchup.active_model.selection.clear
	Sketchup.active_model.selection.add lstnewfaces
end

def JointPushPull.redo
	if @jppclass
		Sketchup.active_model.select_tool nil
		return unless @jppclass.check_selection
		@jppclass.process_push_pull 
	else
		UI.beep
		Traductor.messagebox STR_MsgNoRedo
	end		
end

def JointPushPull.save(jppclass, type, name, lstfaces, lstcenters, tooltip)
	@jppclass = jppclass
	@jpp_type = type
	@jpp_name = name
	@list_faces = []
	@list_centers = []
	lstfaces.each { |f| @list_faces.push f }
	lstcenters.each { |p| @list_centers.push p }
	@cmd_redo.tooltip = Traductor[DLG_TipRedo] + ": " + tooltip
	@saved_entities = []
	Sketchup.active_model.active_entities.each { |e| @saved_entities.push e }
end

#--------------------------------------------------------------------------------------------------------------
# Class JointPushPull: implements both Joint and Vector Push Pull
#--------------------------------------------------------------------------------------------------------------			 
class JPP

JPP_FaceData = Struct.new("JPP_FaceData", :face, :newnormal, :newfaces, :lvd, :embedded, :innerto) 
JPP_VxData = Struct.new("JPP_VxData", :vertex, :lfaces, :vec, :pt) 

def initialize(type)
	@pp_type = type
	@option_border = (@pp_type == 'N') ? 'A' : 'O'
	@option_group = false
	@option_finishing = 'D'
	@distance = 20.cm
	@option_extended = true
	@option_angle = 30.degrees
	@param_direction = nil
	@distance0 = 20.cm
	@planegrid = PlaneGrid.new if (@pp_type == 'J')
	Traductor.load_translation JointPushPull, /MSG_/, binding, "@msg_"
	@tw = Sketchup.create_texture_writer
	@ctrl_down = 0
	
	case type
	when 'J'
		@pp_title = Traductor[DLG_Title_J]
	when 'N'
		@pp_title = Traductor[DLG_Title_N]
	else
		@pp_title = Traductor[DLG_Title_V]
	end	
	@custom_direction_prev = nil

end

#Invoke the Push Pull operation from an extrenal script.
#NOTE: this method odes not do any chcek as there are supposed to be done by the calling method JointPushPull.do_pp
def api_call(selection, distance, vector, finishing, border, group, influence, angle)
	if (@pp_type == 'V') 
		@lst_faces = []
		selection.each { |e| @lst_faces.push e if (e.class == Sketchup::Face) }
		maindir = compute_maindir
		if maindir % vector < 0
			vector = vector.reverse
			if (@option_finishing != 'R')
				distance = - distance
			end
		end	
	end	
	@distance = distance
	@param_direction = vector
	@option_finishing = finishing
	@option_border = border
	@option_group = group
	@option_extended = influence
	@option_angle = angle
	
	return JPP_ERROR_InvalidSelection unless check_selection selection
	process_push_pull
	return 0
end

def check_selection(selection=nil)
	#@tw = Sketchup.create_texture_writer
	@model = Sketchup.active_model
    @entities = @model.active_entities
    @selection = (selection) ? selection : @model.selection
	@lst_faces = []
	@list_centers = []
	@hsh_flayers = {}
	@operation_started = false
	
	#Counting the faces
	@selection.each do |e| 
		if (e.class == Sketchup::Face)
			@lst_faces.push e
			@list_centers.push e.bounds.center
			@hsh_flayers[e.to_s] = e.layer
		end
	end	
	if (@lst_faces.length == 0)
		UI.beep
		Traductor.messagebox STR_MsgNoSelection
		return false
	end	
	
	return true
end

def start_input
	return unless check_selection
	
	#open the tool
	cursor = "JPP_" + @pp_type + ".png"
	if (@pp_type == 'V') 
		@vtool = VectorSelectorTool.new(self, nil, compute_maindir, cursor, @pp_title)
	else
		precompute_J if @pp_type == 'J'
		@vtool = VectorSelectorTool.new(self, @lst_faces, nil, cursor, @pp_title)
	end	
	@model.select_tool @vtool
end
	
def process_push_pull	
	#building the data structures for faces and vertices
	@hsh_faces = {}
	@hsh_vertices = {}
	@hsh_border_edges = {}
	@hsh_alone_edges = {}
	@hsh_new_edges = {}
	@embedmax = 0
	
	#preparing data
	compute_all_data @distance
	
	#Initializing the progress bar
	@pbar = ProgressionBar.new @hsh_faces.length, STR_MsgPB_Completion
	
	#Performing the Joint Push Pull on selected faces
	@model.start_operation @pp_title
		@grp = @entities.add_group 
		build_all_faces
		@hsh_alone_edges.each { |key, e| @entities.erase_entities e if (e.valid?)} if @option_finishing == 'D'
		@grp.explode unless @option_group
	@model.commit_operation	
	
	#saving the operation for future Undo / Redo
	JointPushPull.save self, @pp_type, @pp_title, @lst_faces, @list_centers, @pp_title + " (#{@distance.to_l})"
	
	return true
end

def compute_all_data (distance)
	@hsh_faces = {}
	@hsh_vertices = {}
	@lst_faces.each {|face| compute_data(face) }
	if (@hsh_faces.length == 0)
		@param_direction = nil
		compute_all_data distance
		UI.beep
		Traductor.messagebox((@pp_type == 'V') ? STR_MsgInvalidVector : STR_MsgInvalidProjection)
		return
	end	
	
	if (@pp_type == 'J')
		status = true
		@hsh_vertices.each do |item, vd| 
			unless compute_vertex_offset vd, distance
				status = false
				break
			end
		end	
		unless status
			@param_direction = nil
			compute_all_data distance
			UI.beep
			Traductor.messagebox STR_MsgInvalidProjection
			return
		end
	end	
	true
end

def precompute_J
	compute_all_data @distance0
	compute_palette @model.active_view
end

def vector_selector_getnormal(face)
	new_normal face
end

#Call back for describing additional parameters in the status bar
def vector_selector_option
	msg = "{"
	msg += " " + Traductor.s(DLG_InfoFinishing[@option_finishing]) 
	msg += " - " + Traductor.s(DLG_InfoBorders[@option_border])
	msg += " - " + Traductor.s(DLG_InfoGroup) if @option_group
	if (@pp_type == 'J')
		msg += " - " + Traductor.s(DLG_InfoInfluence) if @option_extended
		msg += " - " + Traductor.s(DLG_InfoAngleInfluence) + ": " + sprintf("%3.1f ", @option_angle.radians) + " degree"
	end
	msg += "}  (" + Traductor[DLG_PressTab] + ")"
	return msg
end

#Call back for dialog box setting up additional parameters
def vector_selector_dialog
	#create the dialog box only once
	unless @dlg
		@hsh_params = {}
		@dlg = Traductor::DialogBox.new @pp_title 
		@dlg.field_enum "Finishing", DLG_Finishing, 'D', DLG_EnumFinishing, ['D', 'R', 'K']
		@dlg.field_enum "Borders", DLG_Borders, 'O', DLG_EnumBorders, ['O', 'A', 'N']
		@dlg.field_enum "Group", DLG_KeepAsGroup, 'N', DLG_EnumYesNo
		if (@pp_type == 'J')
			@dlg.field_enum "Extended", DLG_Extended, 'Y', DLG_EnumYesNo
			@dlg.field_numeric "AngleInfluence", DLG_AngleInfluence, 30, 0, 75 
		end	
	end	

	#Invoking the dialog box
	@hsh_params["Borders"] = @option_border
	@hsh_params["Group"] = (@option_group) ? 'Y' : 'N'
	@hsh_params["Finishing"] = @option_finishing
	if @pp_type == 'J'
		@hsh_params["Extended"] = (@option_extended) ? 'Y' : 'N'
		@hsh_params["AngleInfluence"] = @option_angle.radians
	end	
	return false unless @dlg.show! @hsh_params		

	#transfering the parameters
	@option_border = @hsh_params["Borders"]
	@option_group = (@hsh_params["Group"] == 'Y') ? true : false
	@option_finishing = @hsh_params["Finishing"]
	if @pp_type == 'J'
		@option_extended = (@hsh_params["Extended"] == 'Y') ? true : false
		@option_angle = @hsh_params["AngleInfluence"].degrees
	end	
	precompute_J if @pp_type == 'J'	
	return true
end

def vector_selector_plane
	@model.select_tool PlaneSelectorTool.new(self, @param_direction, nil, @pp_title)
end

#callback for Plane Selection
def plane_selector_execute(origin, normal)
	@param_direction = normal
	@custom_direction_prev = normal.clone
	precompute_J
	@model.select_tool @vtool
end

def plane_selector_cancel
	@model.select_tool @vtool
end

#callback for Vector Selection
def vector_selector_cancel
	Sketchup.active_model.select_tool nil
	restore_faces_after_edition
end

def vector_selector_execute(vector, distance)
	restore_faces_after_edition
	return unless vector || distance	#cancel operation
	
	if (@pp_type == 'V')
		@param_direction = vector
	elsif (@pp_type == 'N')
		@param_direction = nil
	end
	@distance = distance
	process_push_pull
end

#compute the main direction of face normals for Vector Push Pull
def compute_maindir
	x = y = z = 0.0
	@lst_faces.each do |f|
		x += f.normal.x
		y += f.normal.y
		z += f.normal.z
	end	
	Geom::Vector3d.new x, y, z
end

#Build all faces by starting with less embedded faces
def build_all_faces
	@hsh_faces.each { |face_id, fd| optimize_face_with_hole fd } if @pp_type == 'J'	
	@hsh_faces.each { |face_id, fd| check_inner_face fd }	
	@hsh_faces.each { |face_id, fd| equalize_inner_levels fd }	#to converge the embedded status
	for i in 0..@embedmax
		@hsh_faces.each { |key, fd| build_face fd if fd.embedded == i }
	end	
end

#build data structures for faces and vertex
def compute_data(face)
	#Computing the face data
	newnormal = new_normal face
	return unless newnormal
	@hsh_faces[face.to_s] = fd = JPP_FaceData.new
	fd.face = face
	fd.lvd = []
	fd.newnormal = newnormal
	fd.embedded = 0
	fd.innerto = nil
	
	#computing the vertex data
	face.outer_loop.vertices.each do |v|
		vd  = @hsh_vertices[v.to_s]
		unless vd
			@hsh_vertices[v.to_s] = vd = JPP_VxData.new
			vd.lfaces = []
		end	
		vd.lfaces.push fd
		vd.vertex = v
		fd.lvd.push vd
	end
end

#check which faces are embedded and add the holes (inner loop) to the data structures
def check_inner_face(fd)
	face = fd.face
	face.loops.each do |l|
		next if l.outer?
		l.vertices.each do |v|
			vd = @hsh_vertices[v.to_s]
			unless vd
				@hsh_vertices[v.to_s] = vd = JPP_VxData.new
				vd.vertex = v
			end
			v.faces.each do |f|
				fdi = @hsh_faces[f.to_s]
				fdi.innerto = fd if (fdi && f != face)
			end
		end	
	end
end

#Build the tree of embedded faces
def equalize_inner_levels(fd)
	fdi = fd
	n = 0
	while (fdi = fdi.innerto)
		n += 1
	end
	fd.embedded = n
	@embedmax = n unless @embedmax > n
end

#Compute the normal vector to the face, corrected from the privileged plan or vector
def	new_normal(face)
	if @param_direction
		if (@pp_type == 'V')
			newnormal = @param_direction
		else
			pt0 = ORIGIN.offset face.normal, @distance.abs
			newnormal = ORIGIN.vector_to pt0.project_to_plane([ORIGIN, @param_direction])
		end	
	else
		newnormal = face.normal
	end	
	return (newnormal.valid? && ! newnormal.perpendicular?(face.normal)) ? newnormal.normalize : nil
end

#Compute the normal and offset to be used at each vertex in outer loops
def compute_vertex_offset(vd, distance)
	anglelimit = @option_angle
	lvec = []
	vd.lfaces.each {|fd| lvec.push fd.face.normal.normalize }
	vd.vec = nil
	lvec = group_vectors lvec.reverse
	lvec = lvec.collect { |v| project_vector v, @param_direction } if @param_direction
	vd.vec = average_vectors lvec
	
	#computing the length of offset vector
	cosinus = 0.0
	vd.lfaces.each do |fdd| 
		normal = fdd.face.normal
		normal = project_vector normal, @param_direction if @param_direction
		cosinus += Math::cos normal.angle_between(vd.vec) 
	end	
	cosinus = cosinus / vd.lfaces.length
	d = (cosinus.abs < 0.05) ? 1.0 : 1.0 / cosinus
	vd.pt = vd.vertex.position.offset vd.vec, d * distance
	
	true
end

#Group the vectors
def group_vectors(lvec)
	n = lvec.length - 1
	return lvec if n == 0
	ls = []
	for i in 0..n
		for j in i+1..n
			ls.push [i, j, lvec[i].angle_between(lvec[j])]
		end
	end	
	ls.sort! { |a, b| a[2] <=> b[2] }
	
	zero = 0.00001
	anglemax = ls[-1][2]
	tol = anglemax * 0.25
	
	lvres = []
	for i in 0..n
		lvres[i] = [i]
	end	
	ls.each do |a|
		i, j, angle = a
		if angle < zero 
			lvres[j] = nil
		elsif angle <= tol && lvres[i] && lvres[j]
			lvres[i].push j
			lvres[j] = nil
		end
	end
	lvres = lvres.find_all { |a| a }
	lvres = lvres.collect { |a| vector_straght_average a.collect { |i| lvec[i] } }
	lvres = [vector_straght_average(lvec)] if anglemax < 0.5
	lvres	
end

#Straight average of vectors
def vector_straght_average(lvec)
	x = y = z = 0
	lvec.each { |v| x += v.x ; y += v.y ; z += v.z }
	Geom::Vector3d.new(x, y, z).normalize
end

#Project a vector along a given normal direction
def project_vector(v, direction)
	pt = Geom::Point3d.new(v.x, v.y, v.z).project_to_plane [ORIGIN, direction]
	ORIGIN.vector_to(pt).normalize
end

#Compute the average of a list of vectors - Return a normalized vector - Not really based on Choleski!!
def average_vectors(lvec)
	n = lvec.length - 1
	case n
	when -1, 0
		return lvec[0]
		
	when 1	
		return Geom::Vector3d.linear_combination(0.5, lvec[0], 0.5, lvec[1]).normalize
	
	when 2
		lplane = lvec.collect { |v| [Geom::Point3d.new(v.x, v.y, v.z), v] }
		line = Geom.intersect_plane_plane lplane[0], lplane[1]
		return average_vectors([lvec[0], lvec[2]]) unless line
		pt = Geom.intersect_line_plane line, lplane[2]
		return average_vectors([lvec[0], lvec[1]]) unless pt
		return Geom::Vector3d.new(pt.x, pt.y, pt.z).normalize
	
	end
	
	vector_straght_average lvec
end

#Force planar configuration of faces with holes
def optimize_face_with_hole(fd)
	return if fd.face.loops.length == 1
	pts = []
	fd.lvd.each { |vd| pts.push vd.pt }
	plane = Geom.fit_plane_to_points pts
	fd.lvd.each { |vd| vd.pt = vd.pt.project_to_plane plane}
end

#Build one full face, with borders and holes
def build_face(fd)
	face = fd.face
	#face.reverse! if (@option_finishing == 'R' && @distance > 0)
	pts = []
	pts_ref = []
	if (@pp_type != 'J')
		vec = (@pp_type == 'N') ? face.normal : @param_direction	#Classic and Vector Push pull
		face.outer_loop.vertices.each { |v| @hsh_vertices[v.to_s].pt = v.position.offset vec, @distance}
	end	
	face.outer_loop.vertices.each { |v| pts.push @hsh_vertices[v.to_s].pt }
	face.outer_loop.vertices.each { |v| pts_ref.push v.position }
	if (@option_finishing == 'R' && @distance < 0)
		pts.reverse!
		pts_ref.reverse!
	end	
	triangulate_face fd, pts, pts_ref
	face.reverse! if (@option_finishing == 'R' && @distance > 0)
	
	#Building the borders for ALL faces (unless faces are coplanar)
	if (@option_border == 'A')
		face.outer_loop.edges.each do |e| 
			next if @hsh_border_edges[e.to_s]
			f1 = f2 = nil
			e.faces.each do |f|
				if @hsh_faces[f.to_s]
					if f1
						f2 = f
						break
					else
						f1 = f
					end
				end
			end	
			if f1 && f2 && (f1.normal.samedirection? f2.normal)
				@hsh_alone_edges[e.to_s] = e
				@hsh_border_edges[e.to_s] = e
			else
				build_edge_border(fd, e) 
			end	
		end		
		
	#Building the borders for OUTER  faces only
	elsif (@option_border == 'O')
		face.outer_loop.edges.each do |e| 
			next if @hsh_border_edges[e.to_s]
			@hsh_border_edges[e.to_s] = e
			n = 0
			e.faces.each { |f| n += 1 if @hsh_faces[f.to_s] }
			if (n == 1) 
				build_edge_border(fd, e) if edge_alone? e
			else
				@hsh_alone_edges[e.to_s] = e
			end	
		end
	end	
	
	#Handling faces with holes
	create_holes fd
	
	#Erasing the original face
	@entities.erase_entities face if (@option_finishing == 'D')
	
	@pbar.countage		#Face treated
end

#Building the new offset face - This may require to triangulate it
def triangulate_face(fd, pts, pts_ref)
	fd.newfaces = []
	lvxnum = []
	n = pts.length - 1
	lvxnum = (0..n).to_a
	polygon_divide(fd.face, fd.newfaces, pts, pts_ref, lvxnum)
end

#Recursive functions to triangulate the face
def polygon_divide(originalface, lstfaces, pts, pts_ref, lvxnum)
	newface = util_make_face originalface, lstfaces, pts, lvxnum
	return if newface
	parts = best_diagonal(pts_ref, lvxnum)
	parts.each { |lvx| polygon_divide originalface, lstfaces, pts, pts_ref, lvx }
end

#generate a portion of the new generated face
def util_make_face(originalface, lstfaces, pts, lvxnum)
	lpts = []
	lvxnum.each { |i| lpts.push pts[i] }
	begin
		newface = @grp.entities.add_face lpts
	rescue
		return nil
	end
	lstfaces.push newface
	transfer_drawing_element originalface, newface
	newface.back_material = originalface.back_material
	transfer_texture originalface, newface, true, lvxnum
	transfer_texture originalface, newface, false, lvxnum
	
	#Transfering the properties of edges
	n = lvxnum.length - 1
	for i in 0..n
		k1 = lvxnum[i]
		k2 = (i == n) ? lvxnum[0] : lvxnum[i+1]
		newedge = newface.outer_loop.edges[i]
		a = (k2 - k1).abs
		if ((a == 1) || (a == pts.length-1))	#Edge belongs to original face
			oldedge = originalface.outer_loop.edges[k1]
			transfer_edge oldedge, newedge
		else									#Edge created for triangulation
			newedge.soft = newedge.smooth = true
		end	
	end
	newface
end

#Compute the next best diagonal - This is done on the original face, since it is 'flat'
def best_diagonal(pts_ref, lvxnum)
	nv = lvxnum.length
	nvmax = nv - 3
	pts = []
	lvxnum.each { |i| pts.push pts_ref[i] }
	diag = diffmax = lengmax = nil
	tolerance = 1.1
	
	for i in 0..nvmax
		lim = (i == 0) ? nv - 2 : nv - 1
		for j in (i+2)..lim
			next unless diagonal_valid? pts, i, j
			diffarea = (calculate_area(pts[i..j]) - calculate_area(pts[j..nv-1] + pts[0..i])).abs
			next if (diffmax) && (diffarea >= tolerance * diffmax)
			leng = pts[i].distance pts[j]
			next if (lengmax) && (leng >= tolerance * lengmax)
			diffmax = diffarea
			lengmax = leng
			diag = [i, j]
		end
	end	
	diag = [0, 2] unless diag
	return (diag) ? [lvxnum[diag[0]..diag[1]], lvxnum[diag[1]..nv-1] + lvxnum[0..diag[0]]] : []
end

#Test if a diagonal is valid, that is, in the polygon and not crossing borders
def diagonal_valid?(pts, ibeg, iend)
	#test if middle and points close to diagonal ends are in polygon - Also eliminate colinear diagonals
	[0.1, 0.5, 0.9].each do |v|
		pt = Geom.linear_combination(v, pts[ibeg], 1 - v, pts[iend]) 
		return false unless Geom.point_in_polygon_2D pt, pts, false
	end	
	
	#check if diagonal would cross any edge of the polygon
	n = pts.length-1
	for i in 0..n
		j = (i == n) ? 0 : i+1
		next if ((i == ibeg) || (i == iend) || (j == ibeg) || (j == iend))
		pt = Geom.intersect_line_line [pts[i], pts[j]], [pts[ibeg], pts[iend]]
		return false if ((pt != nil) && ((pt.vector_to pts[ibeg]) % (pt.vector_to pts[iend]) < 0) && 
		                 ((pt.vector_to pts[i]) % (pt.vector_to pts[j]) < 0))
	end	
	true
end

#Calculate the area of a polygone defined by <pts> list of points. This works with concave polygons
def calculate_area(pts)
	n = pts.length - 1
	ptsx = pts + [pts[0]]
	area = 0.0
	for i in 0..n
		j = i+1
		area += ptsx[i].x * ptsx[j].y - ptsx[i].y * ptsx[j].x
	end
	0.5 * area.abs	
end

#check if a vertex define a convex or concave angle
def vertex_convex? (oldface, kprev, kmid, knext)
	lv = oldface.outer_loop.vertices
	vec1 = lv[kprev].position.vector_to lv[kmid].position
	vec2 = lv[kmid].position.vector_to lv[knext].position
	v = vec1.cross vec2
	return (v.valid? && v % oldface.normal > 0)
end

#Position the texture identical from the original face to the new generated face
def transfer_texture(oldface, newface, front, lvxnum)
	m = (front) ? oldface.material : oldface.back_material
	return unless m && m.texture
	uvh = oldface.get_UVHelper front, !front, @tw
	nv = lvxnum.length - 1
	ptuv = []
	for i in 0..nv
		oldpt = oldface.outer_loop.vertices[lvxnum[i]].position
		kprev = (i ==0) ? lvxnum[nv] : lvxnum[i-1]
		kmid = lvxnum[i]
		knext = (i == nv) ? lvxnum[0] : lvxnum[i+1]
		next unless (vertex_convex? oldface, kprev, kmid, knext)	#Ignore when vertex not convex
		ptuv.push newface.outer_loop.vertices[i].position
		ptuv.push((front) ? uvh.get_front_UVQ(oldpt) : uvh.get_back_UVQ(oldpt))
		break if (ptuv.length == 8)
	end
	begin
		newface.position_material m, ptuv, front
	rescue		#apparently some bugs in Sketchup with projected textures!
	end
end

#just transfer the property of an edge
def transfer_edge(edge, newedge)
	newedge.smooth = edge.smooth?
	newedge.soft = edge.soft?
	transfer_drawing_element edge, newedge
end

#generic transfer for any drawing element
def transfer_drawing_element (old_entity, new_entity)
	new_entity.layer = old_entity.layer
	new_entity.material = old_entity.material
	new_entity.visible = old_entity.visible?
	new_entity.receives_shadows = old_entity.receives_shadows?
	new_entity.casts_shadows = old_entity.casts_shadows?
end

#check if a vertex only share a single face within the selection
def vertex_alone? (v)
	n = 0
	v.faces.each { |f| n += 1 if @hsh_faces[f.to_s] }
	return (n == 1)
end

#check if an edge only share a single face within the selection
def edge_alone? (e)
	n = 0
	e.faces.each { |f| n += 1 if @hsh_faces[f.to_s] }
	return (n == 1)
end

#Build the border of a face edge, either as a 4-vertices face or 2 triangles
def build_edge_border(fd, edge)
	#return unless edge_alone? edge
	face = fd.face
	v1 = edge.start
	v2 = edge.end
	pt1 = v1.position
	pt2 = v2.position
	if (@pp_type != 'J')
		newpt1 = pt1.offset fd.newnormal, @distance
		newpt2 = pt2.offset fd.newnormal, @distance
	else
		newpt1 = @hsh_vertices[v1.to_s].pt
		newpt2 = @hsh_vertices[v2.to_s].pt
	end	
		
	begin
		newface = @grp.entities.add_face [pt1, pt2, newpt2, newpt1]
		reverse_as_needed face, newface, pt1, pt2, edge
		mapping_texture_border(face, newface, pt1, pt2, newpt1, newpt2, true, nil)
		mapping_texture_border(face, newface, pt1, pt2, newpt1, newpt2, false, nil)
	rescue
		newface1 = @grp.entities.add_face [pt1, pt2, newpt2]
		reverse_as_needed face, newface1, pt1, pt2, edge
		
		newface2 = @grp.entities.add_face [newpt2, newpt1, pt1]
		reverse_as_needed face, newface2, pt1, pt2, edge

		begin
			mapping_texture_border(face, newface1, pt1, pt2, newpt1, newpt2, true, newface2)
			mapping_texture_border(face, newface1, pt1, pt2, newpt1, newpt2, false, newface2)
		rescue
		end	
			
		#Taking care of the diagonal
		newedges = @grp.entities.add_edges newpt2, pt1
		e = newedges[0]
		transfer_edge edge, e
		e.soft = e.smooth = true
	end
	
	#Taking care of the edge for the new face
	alone = edge_alone? edge
	newedges = @grp.entities.add_edges pt1, pt2
	transfer_edge edge, newedges[0]
	
	newedges = @grp.entities.add_edges newpt1, newpt2
	e = newedges[0]
	transfer_edge edge, e
	e.soft = e.smooth = false if alone
	
	#Taking care of the edge for the borders
	newedges = @grp.entities.add_edges pt1, newpt1
	e = newedges[0]
	unless @hsh_new_edges[e.to_s]
		@hsh_new_edges[e.to_s] = e
		transfer_edge edge, e
		e.soft = e.smooth = (alone && vertex_alone?(v1) && (!edge.curve || edge == edge.curve.first_edge)) ? false : true
	end
	
	newedges = @grp.entities.add_edges pt2, newpt2
	e = newedges[0]
	unless @hsh_new_edges[e.to_s]
		@hsh_new_edges[e.to_s] = e
		transfer_edge edge, e
		e.soft = e.smooth = (alone && vertex_alone?(v2) && (!edge.curve || edge == edge.curve.last_edge)) ? false : true
	end
end

#Sketchup logic to orientate face is like the secret of pyramids!!
def reverse_as_needed (oldface, newface, pt1, pt2, edge)
	transfer_drawing_element oldface, newface
	newface.back_material = oldface.back_material
	ptmid = Geom.linear_combination(0.5, pt1, 0.5, pt2)
	pt = ptmid.offset newface.normal, 0.1
	pt = pt.project_to_plane oldface.plane
	newface.reverse! if (within_face oldface, pt)
	newface.reverse! if (@distance < 0 && @option_finishing != 'R')
end

def within_face(face, pt)
	return (face.classify_point(pt) == 1) if SU_MAJOR_VERSION_6
	pts = []
	face.outer_loop.vertices.each { |v| pts.push v.position }
	Geom.point_in_polygon_2D pt, pts, false
end

#Most complex routine to find the right way to map the texture on the borders
def mapping_texture_border(oldface, newface, pt1, pt2, newpt1, newpt2, front, newface2)
	m = (front) ? oldface.material : oldface.back_material
	return nil unless m && m.texture
	uvh = oldface.get_UVHelper front, !front, @tw
	puv1 = (front) ? uvh.get_front_UVQ(pt1) : uvh.get_back_UVQ(pt1)
	puv2 = (front) ? uvh.get_front_UVQ(pt2) : uvh.get_back_UVQ(pt2)
	ptc = oldface.bounds.center
	puvc = (front) ? uvh.get_front_UVQ(ptc) : uvh.get_back_UVQ(ptc)
	
	u1 = puv1.x
	v1 = puv1.y
	u2 = puv2.x
	v2 = puv2.y	

	w = m.texture.width
	h = m.texture.height	
	d = pt1.distance newpt1
	vec = (Geom::Vector3d.new((u2-u1) * w, (v2-v1) * h, 0)) * Z_AXIS
	return nil unless vec.valid?
	vec.length = d
	x = vec.x.abs / w
	y = vec.y.abs / h
	ushift = (x - x.round).abs
	vshift = (y - y.round).abs
	if (vshift > ushift)
		u = x.round
		v = y.ceil
	else
		u = x.ceil
		v = y.round
	end
	usign = (vec.x <=> 0)
	vsign = (vec.y <=> 0)
	sense = ((pt1.vector_to(pt2) * pt1.vector_to(newpt1)) % newface.normal) <=> 0.0
	oldsense = ((pt1.vector_to(pt2) * pt1.vector_to(ptc)) % oldface.normal) <=> 0.0
	uvsense = ((puv1.vector_to(puv2) * puv1.vector_to(puvc)) % Z_AXIS) <=> 0.0

	fac = -uvsense * oldsense * sense
	udec = usign * u * fac
	vdec = vsign * v * fac
	
	#Painting rectangular face or first triangle
	u3 = u1 + udec
	v3 = v1 + vdec
	u4 = u2 + u3 - u1
	v4 = v2 + v3 - v1
	puv3 = Geom::Point3d.new u3, v3, puv1.z
	puv4 = Geom::Point3d.new u4, v4, puv1.z
	ptuv = [pt1, puv1, pt2, puv2, newpt2, puv4, newpt1, puv3]
	newface.position_material m, ptuv, front
	
	#taking care of second triangle
	if (newface2)
		sense2 = ((pt1.vector_to(pt2) * pt1.vector_to(newpt1)) % newface2.normal) <=> 0
		u3 = u1 + udec * sense * sense2
		v3 = v1 + vdec * sense * sense2
		u4 = u2 + u3 - u1
		v4 = v2 + v3 - v1
		puv3 = Geom::Point3d.new u3, v3, puv1.z
		puv4 = Geom::Point3d.new u4, v4, puv1.z
		ptuv = [pt1, puv1, pt2, puv2, newpt2, puv4, newpt1, puv3]
		newface2.position_material m, ptuv, front		
	end
end

#Manage the creation of holes in the generated faces
def create_holes(fd)
	face = fd.face
	return if face.loops.length == 1		#no hole in face
	
	if (@pp_type != 'J')
		face.loops.each { |l| dig_hole_V(fd, l) unless l.outer? }
	elsif (fd.newfaces.length == 1)
		face.loops.each { |l| dig_flat_hole_J(fd, l) unless l.outer? }
	else
		face.loops.each { |l| dig_complex_hole_J(fd, l) unless l.outer? }
	end	
end

#Simple algorithm, as Vector Push Pull preserves faces
def dig_hole_V(fd, loop)		
	pts = []
	loop.vertices.each { |v| pts.push v.position.offset(fd.newnormal, @distance) }
	newface = @grp.entities.add_face pts
	lstedges = []
	loop.edges.each { |e| lstedges.push e if (edge_alone? e) }
	@grp.entities.erase_entities newface unless (lstedges.length == 0)
	lstedges.each { |e|	build_edge_border fd, e } if (@option_border != 'N')
end

#Algorithm to compute vertex positions for holes and embedded faces when generated face is planar
def dig_flat_hole_J(fd, loop)
	pts = []
	plane = fd.newfaces[0].plane
	loop.vertices.each do |v|
		vd = @hsh_vertices[v.to_s]
		vd.vec = average_vector_loop fd, v
		pt = Geom.intersect_line_plane [v.position, vd.vec], plane 
		pts.push pt
		vd.pt = pt.clone
	end
	newface = @grp.entities.add_face pts
	lstedges = []
	loop.edges.each { |e| lstedges.push e if (edge_alone? e) }
	@grp.entities.erase_entities newface unless (lstedges.length == 0)
	lstedges.each { |e|	build_edge_border fd, e } if (@option_border != 'N')	
end

#TO DO: Algorithm to compute vertex positions for holes and embedded faces when generated face is triangulated
def dig_complex_hole_J(fd, loop)

end

#Compute position of vertices for loops, based on embedding face
def average_vector_loop(fd, v)
	pt = v.position
	x = y = z = 0.0
	n = fd.lvd.length - 1
	for i in 0..n
		j = (i == n) ? 0 : i + 1
		vd1 = fd.lvd[i]
		vd2 = fd.lvd[j]
		d1 = pt.distance vd1.vertex.position
		d2 = pt.distance vd2.vertex.position
		d = pt.distance_to_line [vd1.vertex.position, vd2.vertex.position]
		vv = Geom::Vector3d.linear_combination(d2, vd1.vec, d1, vd2.vec)
		fac = 1 / d
		x += vv.x * fac
		y += vv.y * fac
		z += vv.z * fac
	end
	vec = Geom::Vector3d.new x, y, z
	vec.length = 1.0
	vec
end

def hide_show_face(face, vec, dist)
	if (vec % face.normal < 0 || dist < 0)
		prepare_edition
		unless face.layer == @jpp_layer
			face.layer = @jpp_layer
			@selection.remove face
		end	
	else
		if face.layer == @jpp_layer
			face.layer = @hsh_flayers[face.to_s]
			@selection.add face
		end	
	end
end

def prepare_edition
	return if @operation_started
	Sketchup.active_model.start_operation "Visual Push Pull"
	@jpp_layer = Sketchup.active_model.layers.add "JPP$$$__"
	@operation_started = true
	update_edition
end	

def update_edition
	return unless @operation_started
	@jpp_layer.visible = (@option_finishing == 'D') ? false : true
end

def restore_faces_after_edition
	return unless @operation_started
	Sketchup.active_model.abort_operation
	@selection.add @lst_faces
	@operation_started = false
end

#Callback method of the Vector Selector tool for interactive feedback
def vector_selector_draw(view, vec, dist)
	#vector Push Pull simulation
	if (@pp_type == 'V')		
		return unless vec && dist && vec.valid?
		pts = []
		@lst_faces.each_with_index do |face, n|
			face.loops.each do |l|
				l.edges.each do |e|
					ptbeg = e.start.position
					ptend = e.end.position
					ptnbeg = ptbeg.offset vec, dist
					ptnend = ptend.offset vec, dist
					if @option_border == 'N'
						pts.push ptnbeg, ptnend
					else
						pts.push ptbeg, ptend, ptbeg, ptnbeg, ptend, ptnend, ptnbeg, ptnend
					end	
				end
			end
			hide_show_face face, vec, dist
			break if n > MAX_VISUAL_FACES
		end
		
	#Normal Push Pull simulation	
	elsif (@pp_type == 'N')		
		return unless dist != 0
		pts = []
		@lst_faces.each_with_index do |face, n|
			vec = face.normal
			face.loops.each do |l|
				l.edges.each do |e|
					ptbeg = e.start.position
					ptend = e.end.position
					ptnbeg = ptbeg.offset vec, dist
					ptnend = ptend.offset vec, dist
					if @option_border == 'N'
						pts.push ptnbeg, ptnend
					else
						pts.push ptbeg, ptend, ptbeg, ptnbeg, ptend, ptnend, ptnbeg, ptnend
					end	
				end
			end
			hide_show_face face, vec, dist
			break if n > MAX_VISUAL_FACES
		end	
	
	#Joint Push Pull simulation
	else		
		return unless dist != 0
		pts = []
		@lst_faces.each_with_index do |face, n|
			lv = face.outer_loop.vertices
			nv = lv.length - 1
			for i in 0..nv
				v1 = lv[i]
				v2 = (i == nv) ? lv[0] : lv[i+1]
				vd1 = @hsh_vertices[v1.to_s]
				vd2 = @hsh_vertices[v2.to_s]
				d1 = v1.position.distance vd1.pt
				d2 = v2.position.distance vd2.pt
				pt1 = v1.position.offset vd1.vec, d1 * dist / @distance0
				pt2 = v2.position.offset vd2.vec, d2 * dist / @distance0
				if @option_border == 'N'
					pts.push pt1, pt2
				else
					pts.push v1.position, pt1, pt1, pt2
				end	
			end		
			hide_show_face face, face.normal, dist
			break if n > MAX_VISUAL_FACES
		end
	end
	
	#drawing the wireframe
	if @option_group
		view.line_stipple = "-"
		view.line_width = 4
		view.drawing_color = "orange"
	else
		view.line_stipple = ""
		view.line_width = 2
		view.drawing_color = "purple"
	end
	view.draw_lines pts	
end

def vector_selector_finishing
	case @option_finishing
	when 'K'
		@option_finishing = 'R'
	when 'R'
		@option_finishing = 'D'
	when 'D'
		@option_finishing = 'K'
	end	
	update_edition
	@vtool.info_show
end

def vector_selector_borders
	case @option_border
	when 'N'
		@option_border = 'O'
	when 'O'
		@option_border = (@pp_type != 'N') ? 'N' : 'A'
	when 'A'
		@option_border = 'N'
	end	
	@vtool.info_show
end

def vector_selector_group
	@option_group = ! @option_group
	@vtool.info_show
end

def vector_selector_extended
	return unless @pp_type == 'J'
	@option_extended = ! @option_extended
	@vtool.info_show
	precompute_J
end

def vector_selector_angle
	return unless @pp_type == 'J'
	if (@option_angle == 0)
		@option_angle = @option_angle_old
	else
		@option_angle_old = @option_angle
		@option_angle = 0
	end
	@vtool.info_show
	precompute_J
end

def vector_selector_menu(menu)
	if @pp_type == 'J'
		text = @msg_MnuPP
		menu.add_separator
		menu.add_item(text + ': ' + @msg_MnuPPNone) { self.change_privileged_plane nil }
		menu.add_item(text + ': ' + @msg_MnuPPBlue) { self.change_privileged_plane Z_AXIS }
		menu.add_item(text + ': ' + @msg_MnuPPRed) { self.change_privileged_plane X_AXIS }
		menu.add_item(text + ': ' + @msg_MnuPPGreen) { self.change_privileged_plane Y_AXIS }
		menu.add_item(text + ': ' + @msg_MnuPPCustom) { self.vector_selector_plane }
	end
	
	menu.add_separator
	txcur = @msg_MnuCurrent
	text = @msg_MnuFinishing + " #{txcur} " + Traductor[DLG_InfoFinishing[@option_finishing]] + ") --> F5"
	menu.add_item(text) { self.vector_selector_finishing }
	text = @msg_MnuBorders + " #{txcur} " + Traductor[DLG_InfoBorders[@option_border]] + ") --> F6"
	menu.add_item(text) { self.vector_selector_borders }
	text = @msg_MnuGroup + " #{txcur} " + Traductor[DLG_EnumYesNo[(@option_group) ? 'Y' : 'N']] + ") --> F7"
	menu.add_item(text) { self.vector_selector_group }
	if @pp_type == 'J'	
		text = @msg_MnuExtended + " #{txcur} " + Traductor[DLG_EnumYesNo[(@option_extended) ? 'Y' : 'N']] + ") --> F8"
		menu.add_item(text) { self.vector_selector_extended }
		text = @msg_MnuAngle + " #{txcur} " + sprintf("%3.1f ", @option_angle.radians) + Traductor[MSG_Degree] + ") --> F9"
		menu.add_item(text) { self.vector_selector_angle }
	end	
end

def vector_selector_palette_draw(view)
	return unless @pp_type == 'J'
	compute_palette view 
	@planegrid.draw view, 2.25 if @param_direction
end

def change_privileged_plane(direction)
	@param_direction = direction
	precompute_J	
end

def vector_selector_palette_key(view, key, flgup)
	return false unless @pp_type == 'J'
	if (flgup == false) && (key == COPY_MODIFIER_KEY)	#Ctrl key
		@ctrl_down = 1
		return true
	end

	return false unless @ctrl_down > 0
	
	if flgup
		case key
		when COPY_MODIFIER_KEY		#call the Plane selector tool
			vector_selector_plane if @ctrl_down == 1
			@ctrl_down = 0
			return true
		when VK_UP
			change_privileged_plane Z_AXIS
		when VK_RIGHT
			change_privileged_plane X_AXIS
		when VK_LEFT
			change_privileged_plane Y_AXIS
		when VK_DOWN
			change_privileged_plane nil
		else
			@ctrl_down = 2
			return false
		end
	end
	
	@ctrl_down = 2
	return true
end

def compute_palette(view)
	dec = @palette_dec = 50
	vpx = view.vpwidth
	vpy = view.vpheight
	@pt_palette = []
	@pt_palette[0] = point_in_2d view, vpx - dec, vpy - dec
	@pt_palette[1] = point_in_2d view, vpx-2*dec, vpy
	@pt_palette[2] = point_in_2d view, vpx, vpy-2*dec
	@pt_palette[3] = point_in_2d view, vpx-2*dec, vpy-2*dec
	@pt_palette[4] = point_in_2d view, vpx, vpy
	
	@planegrid.compute_transformation @pt_palette[0], @param_direction, nil if @param_direction
end

def point_in_2d(view, x, y)
	ray = view.pickray x, y
	Geom.intersect_line_plane ray, [ORIGIN, view.camera.direction]
end

end #class JPP

#--------------------------------------------------------------------------------------------------------------
# Class ProgressionBar: progress bar in the Sketchup Status text area
#--------------------------------------------------------------------------------------------------------------
class ProgressionBar

#Initialization of progress bar
def initialize(nbelts, label)
	@pb_nbelts = nbelts
	@pb_label = Traductor[label]
	@pb_progression = 0
	@pb_rangemax = 200
	@pb_range = 0
	@pb_time0 = Time.now	
end

#Increment the Progression Bar by <nb> steps
def countage(nb=1)
	@pb_progression += nb
	f = 100 * @pb_progression / @pb_nbelts
	percent = f.to_i
	if (percent != @pb_range)
		@pb_range = percent
		n = 1 + percent * @pb_rangemax / 100
		Sketchup::set_status_text "|" * n.to_i
	end	
	Sketchup.set_status_text @pb_label + " #{@pb_progression} / #{@pb_nbelts}", SB_VCB_LABEL
	Sketchup::set_status_text "#{@pb_range}%  -  #{sprintf "%4.2f", Time.now - @pb_time0} sec", SB_VCB_VALUE
end

end #class ProgressionBar

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Tool to select a plane, direction and angle - More or less mimic Skecthup Protractor
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class VectorSelectorTool

def initialize(caller_class, lfaces, maindir, cursorpath=nil, opname="")
	Traductor.load_translation JointPushPull, /MSG_/, binding, "@msg_"
	@caller = caller_class
	@lfaces = lfaces
	@maindir = maindir
	@cursorpath = JointPushPull.get_file cursorpath
	@idcursor = UI::create_cursor @cursorpath, 10, 10 if @cursorpath
	@opname = opname
	@ip_origin = Sketchup::InputPoint.new
	@ip_end = Sketchup::InputPoint.new
	@pt_origin = nil
	@pt_end = nil
	@axis = nil
	@axcolor = 'black'
	@operation_HS = nil
	@state = STATE_V_ORIGIN

	#computing the Interactive Drawing call backs if any
	@hmeth_draw = nil
	if (@caller)
		@hmeth_exec = callback_handle 'vector_selector_execute', 2
		@hmeth_draw = callback_handle 'vector_selector_draw', 3
		@hmeth_dlg = callback_handle 'vector_selector_dialog', 0
		@hmeth_option = callback_handle 'vector_selector_option', 0
		@hmeth_plane = callback_handle 'vector_selector_plane', 0
		@hmeth_cancel = callback_handle 'vector_selector_cancel', 0
		@hmeth_palette_draw = callback_handle 'vector_selector_palette_draw', 1
		@hmeth_palette_key = callback_handle 'vector_selector_palette_key', 3
		@hmeth_menu = callback_handle 'vector_selector_menu', 1
		@hmeth_finishing = callback_handle 'vector_selector_finishing', 0
		@hmeth_borders = callback_handle 'vector_selector_borders', 0
		@hmeth_group = callback_handle 'vector_selector_group', 0
		@hmeth_extended = callback_handle 'vector_selector_extended', 0
		@hmeth_angle = callback_handle 'vector_selector_angle', 0
		@hmeth_getnormal = callback_handle 'vector_selector_getnormal', 1
	end	
end

def callback_handle(name, arity)
	hmeth = @caller.method name
	hmeth = nil unless (hmeth && hmeth.arity == arity)
	hmeth
end

def activate
	LibFredo6.register_ruby 'JoinPushPull' if defined?(LibFredo6.register_ruby)
	info_show
	Sketchup.active_model.active_view.invalidate
end

def deactivate(view)
	@hmeth_cancel.call
	view.invalidate
end

def getMenu(menu)
	if (@state >= STATE_V_END)
		menu.add_item(@msg_MnuDone) { call_execute }
	end	
	menu.add_item(@msg_MnuOption) { call_dlg }
	@hmeth_menu.call menu
end

def onSetCursor
	UI::set_cursor @idcursor if (@idcursor != 0)
end

def compute_vec_dist
	@vector = @pt_origin.vector_to @pt_end
	@distance = @pt_origin.distance(@pt_end)
	vec = (@lfaces) ? @face.normal : @maindir
	if (vec % @vector < 0)
		@vector = @vector.reverse
		@distance = - @distance
	end	
end

def call_execute
	return UI.beep unless @hmeth_exec
	begin
		compute_vec_dist
		if @hmeth_exec.call @vector, @distance
			Sketchup.active_model.select_tool nil 
			return
		else
			@axis = nil
			set_state STATE_V_END
		end	
	rescue
		@axis = nil
		set_state STATE_V_END
		UI.beep
		Traductor.messagebox "General Problem: cannot compute the transformation"		
	end	
end

def call_draw(view)
	return unless @hmeth_draw
	begin
		compute_vec_dist
		@hmeth_draw.call view, @vector, @distance
	rescue			
	end
end

def call_dlg
	return unless @hmeth_dlg
	begin
		@hmeth_dlg.call
	rescue			
	end
end

def onLButtonDoubleClick(flags, x, y, view)
	if @state == STATE_V_EXECUTION
		call_execute
	else
		UI.beep
	end
end

def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false

	#handling Privileged plane set up by keys
	return if @hmeth_palette_key.call(view, key, false)
	
	case key
		#Toggling between fixed and variable length
		when COPY_MODIFIER_KEY
			return

		when 13			#Return key
			@enter_down = true
			return
			
		#Calling Finishing options
		when JPP___Finishing
			@hmeth_finishing.call

		#Calling Border options
		when JPP___Borders
			@hmeth_borders.call

		#Calling Group option
		when JPP___Group
			@hmeth_group.call

		#Calling Extended option
		when JPP___Extended
			@hmeth_extended.call

		#Calling Angle option
		when JPP___Angle
			@hmeth_angle.call
			
		#Handling axis lock	
		when VK_UP #UP
			@axis = Z_AXIS
			@axcolor = 'blue'
		when VK_RIGHT #UP
			@axis = X_AXIS
			@axcolor = 'red'
		when VK_LEFT #UP
			@axis = Y_AXIS
			@axcolor = 'lawngreen'
		when VK_DOWN #UP
			@axis = nil
			@axcolor = 'black'
		else
			return
	end	
	onMouseMove(flags, @xend, @yend, view) if (@state >= STATE_V_END)
	view.invalidate
	info_show
end

def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true

	#handling Privileged plane set up by keys
	return view.invalidate if @hmeth_palette_key.call(view, key, true)
	
	case key
	when 13			#Return key
		return unless @enter_down
		@enter_down = false
		return UI.beep if @state < STATE_V_END
		call_execute
	#Calling dialog box
	when 9		#TAB key
		call_dlg
		view.invalidate
		info_show
		return true
	else
		return false
	end	
	true
end

#Control the 4 states of the tool
def set_state(state)
	return if (@lfaces && @face == nil)
	@state = state
	@state = STATE_V_EXECUTION if (@state > STATE_V_EXECUTION)
	@pt_end = nil if @state == STATE_V_END
	
	info_show
end

def onLButtonDown(flags, x, y, view)
	@time_mouse_down = Time.now
	set_state @state + 1
end

def onLButtonUp(flags, x, y, view)
	if (@state == STATE_V_ORIGIN)
		return unless @ip_origin.valid?
	elsif (@state == STATE_V_END)	
		return unless @ip_end.valid? && @pt_end && (@pt_origin != @pt_end)
		delta = Time.now - @time_mouse_down
		dist = (@xend - @xorig) * (@xend - @xorig) + (@yend - @yorig) * (@yend - @yorig)
	    return if (delta < 0.5) && (dist < 100)  
	end
	set_state @state + 1
end

#Handle Escape key and Change of tool
def onCancel(flag, view)
	return @hmeth_cancel.call if (flag != 0) || (@state == STATE_V_ORIGIN)  #Exiting the tool
	set_state @state - 1
end

#OnMouseMove method for Tool
def onMouseMove(flags, x, y, view)
	if @lfaces
		onMouseMove_normal(flags, x, y, view)
	else
		onMouseMove_vector(flags, x, y, view)
	end	
end

def onMouseMove_normal(flags, x, y, view)
	case @state	
	when STATE_V_ORIGIN		#input Origin of Vector
		@ip_origin.pick view, x, y
		break unless @ip_origin.valid?
		@xorig = x
		@yorig = y
		view.tooltip = @ip_origin.tooltip
		@pt_origin = @ip_origin.position if @ip_origin.valid?
		@face = @ip_origin.face
		if (@face && @lfaces.include?(@face))
			@face_contour = []
			@face.outer_loop.vertices.each { |v| @face_contour.push v.position }
			@face_contour.push @face_contour[0]
			@axis = @hmeth_getnormal.call @face
		else
			@face = nil
		end	


	when STATE_V_END			#input End of Vector
		@ip_end.pick view, x, y
		break unless @ip_end.valid?
		@xend = x
		@yend = y
		view.tooltip = @ip_end.tooltip
		if @ip_end != @ip_origin
			@pt_end = compute_lock(view, flags, @ip_end, @hmeth_getnormal.call(@face))
		end	
	end	
	view.invalidate
	info_show
end

def onMouseMove_vector(flags, x, y, view)
	case @state	
	when STATE_V_ORIGIN		#input Origin of Vector
		@ip_origin.pick view, x, y
		@xorig = x
		@yorig = y
		view.tooltip = @ip_origin.tooltip
		@pt_origin = @ip_origin.position if @ip_origin.valid?
	when STATE_V_END			#input End of Vector
		@ip_end.pick view, x, y
		@xend = x
		@yend = y
		view.tooltip = @ip_end.tooltip
		if @ip_end.valid? && @ip_end != @ip_origin
			@pt_end = (@axis) ? compute_lock(view, flags, @ip_end, @axis) : @ip_end.position
		end	
	end	
	view.invalidate
	info_show
end

#Projection of input point for axis lock
def compute_lock(view, flags, ip, vec)
	if (ip.position == @pt_origin) || (vec.parallel? @pt_origin.vector_to(ip.position))
		return ip.position
	elsif (flags == 0) && (ip.degrees_of_freedom == 0)	#When Shift pressed, skip inference
		return ip.position.project_to_line([@pt_origin, vec])
	else
		pvorig = view.screen_coords @pt_origin
		pv0 = view.screen_coords @pt_origin.offset(vec, 100)
		pvip = view.screen_coords ip.position
		pv1 = pvip.project_to_line [pvorig, pv0]
		a = Geom.closest_points [@pt_origin, vec], view.pickray(pv1.x, pv1.y)
		return a[0]
	end	
end

#Input of length in the VCB
def onUserText(text, view) 
	#Joint or Normal Push Pull
	if (@lfaces)
		begin
			len = text.to_l
			if len == 0
				@enter_down = false
				UI.beep
				return				
			end	
			if @state == STATE_V_ORIGIN
				Sketchup.active_model.select_tool nil 
				@hmeth_exec.call nil, len
			else
				@enter_down = false
				if @pt_end
					vec = @pt_origin.vector_to @pt_end
					vref = (@lfaces) ? @face.normal : @maindir
					len = -len if (vec % vref < 0 && len < 0)
				end	
				@pt_end = @pt_origin.offset vec, len
				set_state STATE_V_EXECUTION
				view.invalidate
			end	
		rescue
			UI.beep
		end
		return		
	end

	#Vector Push Pull
	return UI.beep if (@state == STATE_V_ORIGIN || @pt_end == nil || @pt_end == @pt_origin)
	begin
		len = text.to_l
		if len == 0
			@enter_down = false
			UI.beep
			return				
		end	
	rescue
		return UI.beep
	end
	vec = @pt_origin.vector_to @pt_end
	@pt_end = @pt_origin.offset vec, len
	set_state STATE_V_EXECUTION
	view.invalidate
end

#Draw method for tool
def draw(view)
	@hmeth_palette_draw.call view
	if @lfaces
		draw_normal view
	else
		draw_vector view
	end	
	@hmeth_palette_draw.call view
end

def draw_normal(view)
	if (@state >= STATE_V_ORIGIN)
		view.draw_points @pt_origin, 10, 2, 'orange' if @pt_origin
		if (@face)
			view.line_width = 4
			view.drawing_color = "red"
			view.draw GL_LINE_STRIP, @face_contour
		end
	end
	
	if (@state >= STATE_V_END && @pt_end)
		view.draw_points @ip_end.position, 15, 7, @axcolor
		view.set_color_from_line @pt_origin, @pt_end
		view.line_width = 1
		view.draw_lines @pt_origin, @pt_end
		if (@axis && (@pt_end != @ip_end.position))
			view.draw_points @pt_end, 5, 2, 'black'
			view.line_stipple = "-"
			view.draw_lines @pt_end, @ip_end.position
			view.line_stipple = ""
		end		
		call_draw view
	end
end

def draw_vector(view)
	if (@state >= STATE_V_ORIGIN)
		view.draw_points @pt_origin, 10, 2, 'orange' if @pt_origin
	end
	
	if (@state >= STATE_V_END && @pt_end)
		view.draw_points @ip_end.position, 15, 7, @axcolor
		view.set_color_from_line @pt_origin, @pt_end
		view.draw_lines @pt_origin, @pt_end
		if (@axis && (@pt_end != @ip_end.position))
			view.draw_points @pt_end, 5, 2, 'black'
			view.line_stipple = "-"
			view.draw_lines @pt_end, @ip_end.position
			view.line_stipple = ""
		end		
		call_draw view
	end
end

#display information in the Sketchup status bar
def info_show
	case @state
	when STATE_V_ORIGIN
		msg = (@lfaces) ? @msg_Face_Origin : @msg_Vector_Origin
	when STATE_V_END
		msg = (@lfaces) ? @msg_Face_End : @msg_Vector_End
	when STATE_V_EXECUTION
		msg = @msg_Input_Execution + ' ' + @opname
	end
	if (@pt_end)
		compute_vec_dist
		d = @distance.to_l
	else	
		d = ""
	end	
	#d = (@pt_end) ? @pt_origin.distance(@pt_end).to_l : ""
	msg += " " + @hmeth_option.call 
	Sketchup.set_status_text msg	
	Sketchup.set_status_text @msg_Distance, SB_VCB_LABEL
	Sketchup.set_status_text d, SB_VCB_VALUE
end
	
end #Class VectorSelectorTool

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Tool to select a plane, direction and angle - More or less mimic Skecthup Protractor
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
					
class PlaneSelectorTool

def initialize(caller_class, normal_def, cursorpath=nil, opname="")
	Traductor.load_translation JointPushPull, /MSG_/, binding, "@msg_"
	@caller = caller_class
	@cursorpath = cursorpath
	@opname = opname
	@idcursor = 0
	@ip_origin = Sketchup::InputPoint.new
	@origin = ORIGIN
	@axis_def = (normal_def) ? normal_def : Z_AXIS
	@angle_def = 0.0
	@normal_def = @axis_def
	@normal = @axis_def
	@pt_ref = ORIGIN
	@gray_color = Sketchup::Color.new "Gray"
	@face_color = @gray_color
	@planegrid = PlaneGrid.new
	
	#defining the Plane grid
	nv = 4
	leng = 200.cm
	step = leng / nv
	@lptgrid = []
	for i in -nv..nv
		@lptgrid.push Geom::Point3d.new(-leng, i * step, 0), Geom::Point3d.new(leng, i * step, 0)
		@lptgrid.push Geom::Point3d.new(i * step, -leng, 0), Geom::Point3d.new(i * step, leng, 0)
	end
			
	self.compute_origin
	
	if (@cursorpath)
		f = JointPushPull.get_file cursorpath
		@idcursor = UI::create_cursor f, 10, 10
	end	
end

def activate
	LibFredo6.register_ruby 'JoinPushPull' if defined?(LibFredo6.register_ruby)
	set_state STATE_P_ORIGIN
end

def deactivate(view)
	view.invalidate
end

def onSetCursor
	UI::set_cursor @idcursor if (@state == STATE_P_EXECUTION && @idcursor != 0)
end

def getMenu(menu)
	menu.add_item(@msg_MnuDone) { call_execute }
end

def call_execute
	return unless @caller
	hmeth = @caller.method 'plane_selector_execute'
	if (hmeth == nil || hmeth.arity != 2)
		UI.beep
	else
		begin
			if hmeth.call @origin, @normal
				return
			else
				set_state STATE_P_ORIGIN
			end	
		rescue			
		end	
	end
end

def call_cancel
	return unless @caller
	hmeth = @caller.method 'plane_selector_cancel'
	if (hmeth == nil || hmeth.arity != 0)
		UI.beep
	else
        hmeth.call
	end
end

def onLButtonDoubleClick(flags, x, y, view)
	if @state == STATE_P_EXECUTION
		call_execute
	else
		UI.beep
	end
end

def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false
	case key
	when VK_UP
		newnormal = Z_AXIS
	when VK_RIGHT
		newnormal = X_AXIS	
	when VK_LEFT
		newnormal = Y_AXIS.reverse	
	when VK_DOWN
		newnormal = @axis_def
	else
		return false
	end
	@axis_def = newnormal
	if (@normal == @normal_def)
		@normal = @axis_def
		self.compute_origin
		view.invalidate
	end	
	@normal_def = @axis_def
	@angle_def = 0.0
	info_angle @angle_def
end

def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
	case key
	when 13			#Return key
		unless @usertext
			return UI.beep if @state < STATE_P_EXECUTION
			call_execute
		end	
		@usertext = false
	else
		return false
	end	
	true
end

def onUserText(text, view)
	@usertext = true
	angle = parse_angle text
	return UI.beep unless angle
	
	case @state
	when STATE_P_ORIGIN
		@angle_def = angle
		@normal_def = Geom::Transformation.rotation(@origin, @axesD[0], @angle_def) * @axis_def
		@normal = @normal_def
		self.compute_origin
	end
	view.invalidate
	info_angle angle
	set_state @state + 1 unless @state == STATE_P_ORIGIN
end

def parse_angle (text)
	text = text.strip
	if text =~ /^=/
		st = $'
		begin
			if st =~ /d$/i
				sd = formula_float $`
				dangle = Kernel::eval sd
			elsif st =~ /r$/i
				sd = formula_float $`
				angle = (Kernel::eval sd)
				dangle = angle.to_f * 180 / Math::PI
			else
				st = formula_float(st)
				tg = Kernel::eval st
				dangle = (tg == 0.0) ? 0.0 : ((Math.atan2(tg, 1)) * 180 / Math::PI)
			end	
		rescue
			UI.beep
			return false
		end
	elsif text =~ /^(d|.)/
		dangle = text.to_f
	else
		UI.beep
		return false
	end	
	dangle = dangle.modulo 360.0
	angle = dangle * Math::PI / 180
end

def formula_float(s)
	s2 = s.gsub(/\.\d/) { |m| ($`[-1..-1] =~ /\d/) ? m : '0' + m }
	s2.gsub(/\d+/) { |m| m + ((($`[-1..-1] != '.') && ($'[0..0] != '.')) ? '.0' : '') }
end

#Control the 4 states of the tool
def set_state(state)
	@state = state
	@state = STATE_P_EXECUTION if (@state > STATE_P_EXECUTION)
	info_show
end

def onLButtonDown(flags, x, y, view)
	set_state @state + 1
end

#Handle Escape key
def onCancel(flag, view)
	return unless flag == 0
	return call_cancel if (@state == STATE_P_ORIGIN)
	set_state @state - 1
end

def compute_origin
	@axesD = @normal.axes
	@planegrid.compute_transformation(@origin, @normal, @face_color)
end

#OnMouseMove method for Tool
def onMouseMove(flags, x, y, view)
	case @state	
	when STATE_P_ORIGIN		#input Origin and Plane
		@ip_origin.pick view, x, y
		view.tooltip = @ip_origin.tooltip
		face = @ip_origin.face
		@origin = @ip_origin.position
		unless (flags == 4)		#unless Shift Key is down, to lock plane
			if (face)
				ph = view.pick_helper
				ph.do_pick x,y
				best = ph.best_picked
				if (best && best.typename == 'ComponentInstance')
					@normal = best.transformation * (face.normal)
				else
					@normal = @ip_origin.transformation * (face.normal)
				end	
				@face_color = (face.material) ? face.material.color : @gray_color
			else
				@normal = @normal_def
			end
		end	
		self.compute_origin
		view.invalidate
	end	
end

#Draw method for tool
def draw(view)
	if (@state >= STATE_P_ORIGIN)		
		#draw the origin
		@ip_origin.draw view

		#draw the plane grid
		@planegrid.draw view, 1.0
	end
end

#display angle value in the VCB
def info_angle(angle)
	dangle = angle * 180 / Math::PI
	dangle = dangle.modulo 360.0
	Sketchup.set_status_text sprintf("%3.1f ", dangle) + @msg_Degree, SB_VCB_VALUE
end

#display information in the Sketchup status bar
def info_show
	case @state
	when STATE_P_ORIGIN
		msg = @msg_Input_Origin
		label = @msg_PlaneAngle
	when STATE_P_EXECUTION
		msg = @msg_Finish_Plane
		label = @msg_PlaneAngle
	end
	Sketchup.set_status_text msg
	Sketchup.set_status_text label, SB_VCB_LABEL
end
	
#Get color corresponding to a vector direction
def get_color vec
	if (vec == nil || vec.length == 0)
		colorname = "Black"
	elsif (vec.parallel? X_AXIS)
		colorname = "Red"
	elsif (vec.parallel? Y_AXIS)
		colorname = "Lawngreen"
	elsif (vec.parallel? Z_AXIS)
		colorname = "Blue"
	else
		colorname = "Black"
	end		
	color = adjust_color colorname
end

def adjust_color(colorname)
	prox = 25
	color = Sketchup::Color.new colorname
	return color if ((color.red - @face_color.red).abs > prox)
	return color if ((color.blue - @face_color.blue).abs > prox)
	return color if ((color.green - @face_color.green).abs > prox)
	color = Sketchup::Color.new 255 - color.red, 255 - color.green, 255 - color.blue 
end

end #Class PlaneSelectorTool

class PlaneGrid

#defining the Plane grid
def initialize
	nv = 4
	leng = 200.cm
	step = leng / nv
	@lptgrid = []
	for i in -nv..nv
		@lptgrid.push Geom::Point3d.new(-leng, i * step, 0), Geom::Point3d.new(leng, i * step, 0)
		@lptgrid.push Geom::Point3d.new(i * step, -leng, 0), Geom::Point3d.new(i * step, leng, 0)
	end
end

def compute_transformation(origin, normal, face_color)
	axesD = normal.axes
	@origin = origin
	@normal = normal
	@tt = Geom::Transformation.axes origin, axesD[0], axesD[1], axesD[2] 	
	@color = get_color normal, face_color
end

#Get color corresponding to a vector direction
def get_color vec, face_color
	if (vec == nil || vec.length == 0)
		colorname = "Black"
	elsif (vec.parallel? X_AXIS)
		colorname = "Red"
	elsif (vec.parallel? Y_AXIS)
		colorname = "Lawngreen"
	elsif (vec.parallel? Z_AXIS)
		colorname = "Blue"
	else
		colorname = "Black"
	end		
	@color = adjust_color colorname, face_color
end

def adjust_color(colorname, face_color)
	prox = 25
	color = Sketchup::Color.new colorname
	return color unless face_color
	return color if ((color.red - face_color.red).abs > prox)
	return color if ((color.blue - face_color.blue).abs > prox)
	return color if ((color.green - face_color.green).abs > prox)
	color = Sketchup::Color.new 255 - color.red, 255 - color.green, 255 - color.blue 
end

def draw(view, factor)
	#Compute the right scale to keep the protractor the same size
	size = view.pixels_to_model 1, @origin 	
	t = @tt * Geom::Transformation.scaling(size / factor)
	
	#draw the plane grid
	view.drawing_color = @color 
	view.line_stipple = ""
	view.line_width = 2
	pts = []
	@lptgrid.each {|pt| pts.push view.screen_coords(t * pt)}
	view.draw2d GL_LINES, pts
	#view.draw_lines pts
end

end  #class Plane Grid
#--------------------------------------------------------------------------------------------------------------
# Public methods of module JointPushPull
#--------------------------------------------------------------------------------------------------------------

def JointPushPull.set_command
	menutool = UI.menu "Tools"
	menutool.add_separator
	menutool = menutool.add_submenu "Joint Push Pull"
	@tlb = nil
	
	#Joint Push Pull Command
	cmd = UI::Command.new(Traductor[DLG_Title_J]) { JointPushPull.execute 'J' }
	menutool.add_item cmd
	tooltip = Traductor[DLG_Title_J]
	JointPushPull.create_button cmd, tooltip, "JPP_J.png"
	
	#Vector Push Pull command
	cmd = UI::Command.new(Traductor[DLG_Title_V]) { JointPushPull.execute 'V' }
	menutool.add_item cmd
	tooltip = Traductor[DLG_Title_V]
	JointPushPull.create_button cmd, tooltip, "JPP_V.png"
	
	#Normal Push Pull command
	cmd = UI::Command.new(Traductor[DLG_Title_N]) { JointPushPull.execute 'N' }
	menutool.add_item cmd
	tooltip = Traductor[DLG_Title_N]
	JointPushPull.create_button cmd, tooltip, "JPP_N.png"
	@tlb.add_separator if @tlb

	#Undo / Redo command command
	cmd = UI::Command.new(Traductor[DLG_MnuUndo]) { JointPushPull.undo }
	menutool.add_item cmd
	tooltip = Traductor[DLG_TipUndo]
	JointPushPull.create_button cmd, tooltip, "JPP_Undo.png"
	cmd.tooltip = Traductor[DLG_TipUndo]
	@cmd_undo = cmd

	#Redo short cut command
	cmd = UI::Command.new(Traductor[DLG_MnuRedo]) { JointPushPull.redo }
	menutool.add_item cmd
	tooltip = Traductor[DLG_TipRedo]
	JointPushPull.create_button cmd, tooltip, "JPP_Redo.png"
	@cmd_redo = cmd
		
	#showing the toolbar
	status = @tlb.get_last_state
	if status == 1
		@tlb.restore
	elsif status == -1	
		@tlb.show if @tlb
	end	
	
	#contextual menu selection (as suggested by Urgen
	UI.add_context_menu_handler do |menu|
		menu.add_separator
		menu = menu.add_submenu "Joint Push Pull"
		menu.add_item(Traductor[DLG_Title_J]) { JointPushPull.execute 'J' }
		menu.add_item(Traductor[DLG_Title_V]) { JointPushPull.execute 'V' }
		menu.add_item(Traductor[DLG_Title_N]) { JointPushPull.execute 'N' }
		menu.add_item(Traductor[DLG_MnuRedo]) { JointPushPull.redo }
	end 
end

def JointPushPull.create_button(cmd, tooltip, iconpath)
	cmd.status_bar_text = tooltip
	icon = JointPushPull.get_file iconpath
	if (icon)
		cmd.tooltip = tooltip
		cmd.small_icon = cmd.large_icon = icon
		@tlb = UI::Toolbar.new NULT_TOOLBAR unless @tlb
		@tlb.add_item cmd
	end	

end

unless $jpp____loaded
	JointPushPull.set_command
	$jpp____loaded = true
end

end #Module JointPushPull
