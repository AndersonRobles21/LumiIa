router.post("/horarios", async (req, res) => {
  const { usuario_id, horarios } = req.body; 
  // 'horarios' es un Array: [{ dia: 'lun', hora_inicio: '14:30', hora_fin: '14:50' }]

  if (!horarios || !Array.isArray(horarios)) {
    return res.status(400).json({ mensaje: "El formato de horarios es inválido." });
  }

  // ========================================================
  // RESTRICCIÓN: Validar choques de horas en el mismo día (JS)
  // ========================================================
  for (let i = 0; i < horarios.length; i++) {
    const actual = horarios[i];
    
    for (let j = i + 1; j < horarios.length; j++) {
      const comparar = horarios[j];

      // Si es el mismo día, revisamos si los rangos de horas se cruzan
      if (actual.dia === comparar.dia) {
        const inicioAct = actual.hora_inicio;
        const finAct = actual.hora_fin;
        const inicioComp = comparar.hora_inicio;
        const finComp = comparar.hora_fin;

        // Fórmula de traslape: (InicioA < FinB) Y (FinA > InicioB)
        if (inicioAct < finComp && finAct > inicioComp) {
          return res.status(400).json({ 
            mensaje: `Conflicto de tiempo: Tienes horarios que se cruzan el día ${actual.dia} (${inicioAct} - ${finAct} con ${inicioComp} - ${finComp}).` 
          });
        }
      }
    }
  }

  // Si pasa la validación, procedemos de manera segura con la Transacción SQL
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Limpiamos los anteriores para reescribir el nuevo estado completo
    await client.query('DELETE FROM horarios WHERE usuario_id = $1', [usuario_id]);

    // Insertamos los nuevos horarios ya validados
    for (const slot of horarios) {
      await client.query(
        'INSERT INTO horarios (usuario_id, dia, hora_inicio, hora_fin) VALUES ($1, $2, $3, $4)',
        [usuario_id, slot.dia, slot.hora_inicio, slot.hora_fin]
      );
    }

    await client.query('COMMIT');
    return res.status(200).json({ mensaje: "Horarios actualizados con éxito de manera segura." });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error(error);
    return res.status(500).json({ mensaje: "Error interno al procesar los horarios." });
  } finally {
    client.release();
  }
});