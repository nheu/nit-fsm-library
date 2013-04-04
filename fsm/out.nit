module out

class Out
	var activated = false

	# accesseur du membre is_activated
	fun is_activated: Bool do return self.activated

	# mutateur du membre is_activated
	fun is_activated=(activated: Bool) do self.activated = activated

	#affichage de message catégorie : détails sur la sortie standard
	fun log(log_type: String, message: String)
	do
		if activated then print log_type + " => " + message
	end

	#affichage de message simple sur la sortie standard
	fun logl(message: String)
	do
		if activated then print message
	end

	fun logChar(log_type: String, char: Char)
	do
		if activated then print log_type + " => " + char.to_s
	end

	fun activate
	do
		activated = true
	end
end


