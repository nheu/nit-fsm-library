module url

#Représente une adresse de ressource
#Dans le cadre de cet mise en oeuvre ResourceLocator est
#également utilisé pour typer l'alphabet de l'automate.
#Tous les symboles reconnus par l'automate sont donc de ce type
class ResourceLocator
	var protocol: String
	var separator: String
	var domain: String
	var resource: String

	init(protocol: String, separator: String, domain: String, resource: String) do
		self.protocol = protocol
		self.separator = separator
		self.domain = domain
		self.resource = resource
	end

	redef fun to_s do
		return "/" + resource
	end

	fun absolute_url: String do
		return protocol + separator + domain + resource
	end
end
