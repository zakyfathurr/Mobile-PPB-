const pool = require('../db');

// POST /trash
async function createScan(req, res) {
  try {
    const { image_url, detected_label, category } = req.body;
    const user_id = req.uid;

    if (!image_url || !detected_label || !category) {
      return res.status(400).json({
        error: 'Missing required fields: image_url, detected_label, category',
      });
    }

    const result = await pool.query(
      `INSERT INTO scan_results (user_id, image_url, detected_label, category)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [user_id, image_url, detected_label, category]
    );

    return res.status(201).json({ message: 'Scan saved', data: result.rows[0] });
  } catch (err) {
    console.error('[createScan]', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

// GET /trash
async function getScans(req, res) {
  try {
    const result = await pool.query(
      `SELECT * FROM scan_results WHERE user_id = $1 ORDER BY created_at DESC`,
      [req.uid]
    );
    return res.status(200).json({ message: 'Success', count: result.rowCount, data: result.rows });
  } catch (err) {
    console.error('[getScans]', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

// PUT /trash/:id
async function updateScan(req, res) {
  try {
    const { id } = req.params;
    const user_id = req.uid;
    const { image_url, detected_label, category } = req.body;

    const existing = await pool.query(
      'SELECT * FROM scan_results WHERE id = $1 AND user_id = $2',
      [id, user_id]
    );
    if (existing.rowCount === 0) {
      return res.status(404).json({ error: 'Scan not found or access denied' });
    }

    const curr = existing.rows[0];
    const result = await pool.query(
      `UPDATE scan_results SET image_url=$1, detected_label=$2, category=$3
       WHERE id=$4 AND user_id=$5 RETURNING *`,
      [
        image_url ?? curr.image_url,
        detected_label ?? curr.detected_label,
        category ?? curr.category,
        id,
        user_id,
      ]
    );

    return res.status(200).json({ message: 'Scan updated', data: result.rows[0] });
  } catch (err) {
    console.error('[updateScan]', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

// DELETE /trash/:id
async function deleteScan(req, res) {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'DELETE FROM scan_results WHERE id=$1 AND user_id=$2 RETURNING id',
      [id, req.uid]
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Scan not found or access denied' });
    }
    return res.status(200).json({ message: `Scan #${id} deleted` });
  } catch (err) {
    console.error('[deleteScan]', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

module.exports = { createScan, getScans, updateScan, deleteScan };
