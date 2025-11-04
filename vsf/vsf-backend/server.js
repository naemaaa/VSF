const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { Pool } = require('pg');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL Connection
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Test database connection
pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
});

pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Database Connection Error:', err);
  } else {
    console.log('✅ PostgreSQL Connected');
  }
});

// ===== ROUTES =====

// ===== USER ROUTES =====

// POST: Register User
app.post('/api/users/register', async (req, res) => {
  try {
    const { email, passwordHash, userType, fullName, nik, organizationName, npwp } = req.body;

    // Validasi
    if (!email || !passwordHash || !userType) {
      return res.status(400).json({ error: 'Email, password, dan userType wajib diisi' });
    }

    // Check email sudah ada
    const existing = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ error: 'Email sudah terdaftar' });
    }

    // Insert user
    const userId = `user_${Date.now()}`;
    await pool.query(
      `INSERT INTO users (id, email, password_hash, user_type, full_name, nik, organization_name, npwp) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [userId, email, passwordHash, userType, fullName, nik, organizationName, npwp]
    );

    res.status(201).json({
      success: true,
      message: 'Registrasi berhasil',
      userId: userId,
      userType: userType,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST: Login User
app.post('/api/users/login', async (req, res) => {
  try {
    const { email, passwordHash } = req.body;

    if (!email || !passwordHash) {
      return res.status(400).json({ error: 'Email dan password wajib diisi' });
    }

    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1 AND password_hash = $2',
      [email, passwordHash]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Email atau password salah' });
    }

    const user = result.rows[0];
    res.json({
      success: true,
      message: 'Login berhasil',
      userId: user.id,
      email: user.email,
      userType: user.user_type,
      fullName: user.full_name || user.organization_name,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: Get User Profile
app.get('/api/users/:id', async (req, res) => {
  try {
    const user = await pool.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
    if (user.rows.length === 0) {
      return res.status(404).json({ error: 'User tidak ditemukan' });
    }

    const userData = user.rows[0];
    res.json({
      id: userData.id,
      email: userData.email,
      userType: userData.user_type,
      fullName: userData.full_name || userData.organization_name,
      nik: userData.nik,
      npwp: userData.npwp,
      phoneNumber: userData.phone_number,
      profileImagePath: userData.profile_image_path,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===== EVENT ROUTES =====

// GET: All Events
app.get('/api/events', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM events WHERE is_active = true ORDER BY created_at DESC'
    );

    const events = result.rows.map(row => ({
      ...row,
      location: {
        country: row.location_country,
        province: row.location_province,
        city: row.location_city,
        district: row.location_district,
        village: row.location_village,
        rtRw: row.location_rt_rw,
        latitude: row.location_latitude,
        longitude: row.location_longitude,
      }
    }));

    res.json(events);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: Single Event
app.get('/api/events/:id', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM events WHERE id = $1 AND is_active = true', [req.params.id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Event tidak ditemukan' });
    }

    const row = result.rows[0];
    const event = {
      ...row,
      location: {
        country: row.location_country,
        province: row.location_province,
        city: row.location_city,
        district: row.location_district,
        village: row.location_village,
        rtRw: row.location_rt_rw,
        latitude: row.location_latitude,
        longitude: row.location_longitude,
      }
    };

    res.json(event);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST: Create Event (Organization only)
app.post('/api/events', async (req, res) => {
  try {
    const {
      title, description, imageUrl, organizerId, organizerName,
      location, eventStartTime, eventEndTime,
      targetVolunteerCount, participationFeeIdr, category
    } = req.body;

    // Validasi
    if (!title || !description || !organizerId || !category) {
      return res.status(400).json({ error: 'Field wajib tidak lengkap' });
    }

    // Verify organizer adalah organization type
    const orgCheck = await pool.query(
      'SELECT * FROM users WHERE id = $1 AND user_type = $2',
      [organizerId, 'organization']
    );

    if (orgCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Hanya organisasi yang bisa membuat event' });
    }

    const eventId = `event_${Date.now()}`;

    await pool.query(
      `INSERT INTO events (
        id, title, description, image_url, organizer_id, organizer_name,
        event_start_time, event_end_time, target_volunteer_count,
        participation_fee_idr, category, is_active,
        location_country, location_province, location_city,
        location_district, location_village, location_rt_rw,
        location_latitude, location_longitude
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)`,
      [
        eventId, title, description, imageUrl, organizerId, organizerName,
        eventStartTime, eventEndTime, targetVolunteerCount,
        participationFeeIdr, category, true,
        location.country, location.province, location.city,
        location.district, location.village, location.rtRw,
        location.latitude, location.longitude
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Event berhasil dibuat',
      eventId: eventId,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: Search Events
app.get('/api/events/search', async (req, res) => {
  try {
    const { title } = req.query;
    const searchTerm = `%${title}%`;

    const result = await pool.query(
      'SELECT * FROM events WHERE is_active = true AND title ILIKE $1 ORDER BY created_at DESC',
      [searchTerm]
    );

    const events = result.rows.map(row => ({
      ...row,
      location: {
        country: row.location_country,
        province: row.location_province,
        city: row.location_city,
        district: row.location_district,
        village: row.location_village,
        rtRw: row.location_rt_rw,
        latitude: row.location_latitude,
        longitude: row.location_longitude,
      }
    }));

    res.json(events);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: Events by Organizer
app.get('/api/events/organizer/:organizerId', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM events WHERE organizer_id = $1 ORDER BY created_at DESC',
      [req.params.organizerId]
    );

    const events = result.rows.map(row => ({
      ...row,
      location: {
        country: row.location_country,
        province: row.location_province,
        city: row.location_city,
        district: row.location_district,
        village: row.location_village,
        rtRw: row.location_rt_rw,
        latitude: row.location_latitude,
        longitude: row.location_longitude,
      }
    }));

    res.json(events);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===== PARTICIPATION ROUTES =====

// POST: Register Participation
app.post('/api/participation', async (req, res) => {
  try {
    const { userId, eventId, donationAmount } = req.body;

    if (!userId || !eventId) {
      return res.status(400).json({ error: 'userId dan eventId wajib' });
    }

    // Check event exists
    const eventCheck = await pool.query('SELECT * FROM events WHERE id = $1', [eventId]);
    if (eventCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Event tidak ditemukan' });
    }

    const event = eventCheck.rows[0];

    // Check if already registered
    if (event.registered_volunteer_ids && event.registered_volunteer_ids.includes(userId)) {
      return res.status(400).json({ error: 'Sudah terdaftar di event ini' });
    }

    // Check if event full
    if (event.current_volunteer_count >= event.target_volunteer_count) {
      return res.status(400).json({ error: 'Event sudah penuh' });
    }

    const participationId = `part_${Date.now()}`;

    // Insert participation
    await pool.query(
      'INSERT INTO participations (id, user_id, event_id, donation_amount) VALUES ($1, $2, $3, $4)',
      [participationId, userId, eventId, donationAmount || 0]
    );

    // Update event volunteer count
    const newVolunteerIds = event.registered_volunteer_ids || [];
    newVolunteerIds.push(userId);

    await pool.query(
      `UPDATE events SET 
       current_volunteer_count = current_volunteer_count + 1,
       registered_volunteer_ids = $1
       WHERE id = $2`,
      [newVolunteerIds, eventId]
    );

    res.status(201).json({
      success: true,
      message: 'Pendaftaran berhasil',
      participationId: participationId,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: User Participations
app.get('/api/participation/user/:userId', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM participations WHERE user_id = $1 ORDER BY registration_date DESC',
      [req.params.userId]
    );
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===== ARTICLES ROUTES =====

// GET: All Articles
app.get('/api/articles', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, title, description, image_url, category, author_name, 
              published_date, is_featured, views 
       FROM articles 
       WHERE is_active = true 
       ORDER BY is_featured DESC, published_date DESC`
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: Featured Articles (untuk home page)
app.get('/api/articles/featured', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, title, description, image_url, category, author_name, 
              published_date, views 
       FROM articles 
       WHERE is_active = true AND is_featured = true 
       ORDER BY published_date DESC 
       LIMIT 5`
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: Single Article Detail
app.get('/api/articles/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM articles WHERE id = $1 AND is_active = true`,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Artikel tidak ditemukan' });
    }

    // Increment views count
    await pool.query(
      'UPDATE articles SET views = views + 1 WHERE id = $1',
      [req.params.id]
    );

    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: Search Articles
app.get('/api/articles/search', async (req, res) => {
  try {
    const { title } = req.query;
    const searchTerm = `%${title}%`;

    const result = await pool.query(
      `SELECT id, title, description, image_url, category, author_name, 
              published_date, views 
       FROM articles 
       WHERE is_active = true AND (title ILIKE $1 OR description ILIKE $1)
       ORDER BY published_date DESC`,
      [searchTerm]
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET: Articles by Category
app.get('/api/articles/category/:category', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, title, description, image_url, category, author_name, 
              published_date, views 
       FROM articles 
       WHERE is_active = true AND category = $1
       ORDER BY published_date DESC`,
      [req.params.category]
    );

    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===== HEALTH CHECK =====

app.get('/api/health', (req, res) => {
  res.json({ status: 'API Running ✅' });
});

// ===== ERROR HANDLING =====

app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// ===== START SERVER =====

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});