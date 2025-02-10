extends Node3D

# Минимальный скрипт сцены: только совместимость эффектов на вебе

func _ready():
	var we: WorldEnvironment = get_node_or_null("WorldEnvironment")
	if we and we.environment:
		var env: Environment = we.environment
		if OS.has_feature("web"):
			# Веб: оставляем эффекты отключёнными (в сцене уже false)
			env.ssr_enabled = false
			env.ssao_enabled = false
			env.volumetric_fog_enabled = false
			print("[Env] Web: SSR/SSAO/Volumetric Fog disabled")
		else:
			# Десктоп: включаем эффекты
			env.ssr_enabled = true
			env.ssao_enabled = true
			env.volumetric_fog_enabled = true
			print("[Env] Desktop: SSR/SSAO/Volumetric Fog enabled")
