-- OriyaEvents Database Schema
-- הרץ את כל הקוד הזה ב-Supabase SQL Editor

-- טבלת משתמשים
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    package_invites INTEGER DEFAULT 0,
    package_sent INTEGER DEFAULT 0,
    package_paid BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- טבלת הזמנות
CREATE TABLE IF NOT EXISTS invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    groom_name TEXT NOT NULL,
    bride_name TEXT NOT NULL,
    event_date DATE NOT NULL,
    event_time TIME NOT NULL,
    venue TEXT NOT NULL,
    address TEXT NOT NULL,
    additional_info TEXT,
    template TEXT DEFAULT 'classic',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- טבלת הזמנות שנשלחו
CREATE TABLE IF NOT EXISTS invitations_sent (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    invitation_id UUID REFERENCES invitations(id) ON DELETE SET NULL,
    guest_name TEXT NOT NULL,
    guest_phone TEXT NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- טבלת תשלומים
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    package_invites INTEGER NOT NULL,
    status TEXT DEFAULT 'pending',
    payment_proof TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES users(id)
);

-- אינדקסים
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_invitations_user_id ON invitations(user_id);
CREATE INDEX IF NOT EXISTS idx_invitations_sent_user_id ON invitations_sent(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);

-- RLS (Row Level Security)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations_sent ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Policies for users
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
    );

DROP POLICY IF EXISTS "Admins can update all users" ON users;
CREATE POLICY "Admins can update all users" ON users
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
    );

-- Policies for invitations
DROP POLICY IF EXISTS "Users can view own invitations" ON invitations;
CREATE POLICY "Users can view own invitations" ON invitations
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own invitations" ON invitations;
CREATE POLICY "Users can create own invitations" ON invitations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own invitations" ON invitations;
CREATE POLICY "Users can update own invitations" ON invitations
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all invitations" ON invitations;
CREATE POLICY "Admins can view all invitations" ON invitations
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
    );

-- Policies for invitations_sent
DROP POLICY IF EXISTS "Users can view own sent invitations" ON invitations_sent;
CREATE POLICY "Users can view own sent invitations" ON invitations_sent
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own sent invitations" ON invitations_sent;
CREATE POLICY "Users can create own sent invitations" ON invitations_sent
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all sent invitations" ON invitations_sent;
CREATE POLICY "Admins can view all sent invitations" ON invitations_sent
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
    );

-- Policies for payments
DROP POLICY IF EXISTS "Users can view own payments" ON payments;
CREATE POLICY "Users can view own payments" ON payments
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create own payments" ON payments;
CREATE POLICY "Users can create own payments" ON payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all payments" ON payments;
CREATE POLICY "Admins can view all payments" ON payments
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
    );

DROP POLICY IF EXISTS "Admins can update all payments" ON payments;
CREATE POLICY "Admins can update all payments" ON payments
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND is_admin = true)
    );

-- פונקציה לספירת הזמנות
CREATE OR REPLACE FUNCTION increment_sent_count(user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE users 
    SET package_sent = package_sent + 1
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;
