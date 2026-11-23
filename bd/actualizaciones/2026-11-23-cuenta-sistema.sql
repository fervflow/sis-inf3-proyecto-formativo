-- Semilla incremental: cuenta de sistema para las reservas del canal web.
INSERT INTO turismo.usuario (id, name, email, id_rol, nombres, apellidos, estado, debe_cambiar_password)
SELECT 'sistema', 'Sistema', 'sistema@vizcacha.tours', r.id_rol,
       'Cuenta de sistema', 'Vizcacha Tours', 'activo', false
FROM turismo.rol r
WHERE r.codigo = 'CLIENTE'
  AND NOT EXISTS (
      SELECT 1 FROM turismo.usuario u WHERE u.id = 'sistema' OR u.email = 'sistema@vizcacha.tours'
  );
