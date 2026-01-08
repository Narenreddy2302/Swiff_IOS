-- ============================================================
-- SWIFF DATABASE SCHEMA FOR SUPABASE
-- Complete PostgreSQL Schema for Financial Management iOS App
-- Version: 1.0.0
--
-- INSTRUCTIONS:
-- Execute this SQL in your Supabase SQL Editor in sections.
-- Each section is marked with a header comment.
-- Wait for each section to complete before running the next.
-- ============================================================

-- ============================================================
-- SECTION 1: EXTENSIONS
-- Run this first to enable required PostgreSQL extensions
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- SECTION 2: ENUM TYPES
-- These define the allowed values for various fields
-- ============================================================

-- Avatar type for profile pictures
CREATE TYPE avatar_type AS ENUM ('photo', 'emoji', 'initials');

-- Billing cycle for subscriptions
CREATE TYPE billing_cycle AS ENUM (
    'daily', 'weekly', 'biweekly', 'monthly',
    'quarterly', 'semi_annually', 'yearly', 'annually', 'lifetime'
);

-- Subscription category
CREATE TYPE subscription_category AS ENUM (
    'entertainment', 'productivity', 'fitness', 'health', 'education',
    'news', 'music', 'cloud', 'gaming', 'design', 'development',
    'finance', 'utilities', 'other'
);

-- Transaction category
CREATE TYPE transaction_category AS ENUM (
    'food', 'dining', 'groceries', 'transportation', 'travel',
    'shopping', 'entertainment', 'bills', 'utilities', 'healthcare',
    'income', 'transfer', 'investment', 'other'
);

-- Payment method
CREATE TYPE payment_method AS ENUM (
    'credit_card', 'debit_card', 'paypal', 'apple_pay',
    'google_pay', 'bank_transfer', 'other'
);

-- Payment status
CREATE TYPE payment_status AS ENUM (
    'pending', 'completed', 'failed', 'refunded', 'cancelled'
);

-- Split type for bill splitting
CREATE TYPE split_type AS ENUM (
    'equally', 'exact_amounts', 'percentages', 'shares', 'adjustments'
);

-- Cost split type for shared subscriptions
CREATE TYPE cost_split_type AS ENUM ('equal', 'percentage', 'fixed', 'free');

-- Account type
CREATE TYPE account_type AS ENUM ('bank', 'credit_card', 'debit_card', 'wallet', 'upi');

-- Transaction type
CREATE TYPE transaction_type AS ENUM ('receive', 'send', 'payment', 'transfer', 'request');

-- Subscription event type for timeline
CREATE TYPE subscription_event_type AS ENUM (
    'billing_charged', 'billing_upcoming', 'price_increase', 'price_decrease',
    'trial_started', 'trial_ending', 'trial_converted',
    'subscription_created', 'subscription_paused', 'subscription_resumed', 'subscription_cancelled',
    'usage_recorded', 'reminder_sent', 'member_added', 'member_removed', 'member_paid'
);

-- Cancellation difficulty
CREATE TYPE cancellation_difficulty AS ENUM ('easy', 'medium', 'hard');

-- Contact method for notifications
CREATE TYPE contact_method AS ENUM ('in_app', 'email', 'sms', 'whatsapp');

-- Invitation status
CREATE TYPE invitation_status AS ENUM ('pending', 'accepted', 'declined', 'expired');

-- Document type
CREATE TYPE document_type AS ENUM ('contract', 'receipt', 'confirmation', 'cancellation');

-- ============================================================
-- SECTION 3: UTILITY FUNCTIONS
-- Helper functions for triggers and operations
-- ============================================================

-- Function to auto-update updated_at and increment sync_version
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.sync_version = COALESCE(OLD.sync_version, 0) + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-create user profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- SECTION 4: USER PROFILES TABLE
-- Extends Supabase auth.users with app-specific data
-- ============================================================

CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT NOT NULL DEFAULT '',
    phone TEXT,

    -- Avatar system
    avatar_type avatar_type DEFAULT 'initials',
    avatar_data BYTEA,
    avatar_emoji TEXT,
    avatar_initials TEXT,
    avatar_color_index INTEGER DEFAULT 0,

    -- Preferences
    default_currency TEXT DEFAULT 'USD',
    timezone TEXT DEFAULT 'UTC',

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL,

    CONSTRAINT valid_avatar CHECK (
        (avatar_type = 'photo' AND avatar_data IS NOT NULL) OR
        (avatar_type = 'emoji' AND avatar_emoji IS NOT NULL) OR
        (avatar_type = 'initials')
    )
);

-- Indexes for user_profiles
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
CREATE INDEX idx_user_profiles_deleted_at ON user_profiles(deleted_at) WHERE deleted_at IS NULL;

-- Trigger for auto-creating profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- SECTION 5: PERSONS TABLE (Contacts)
-- Local contacts/friends that the user tracks
-- ============================================================

CREATE TABLE persons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

    -- Basic info
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    balance DECIMAL(15, 2) DEFAULT 0.00 NOT NULL,

    -- Avatar system
    avatar_type avatar_type DEFAULT 'initials',
    avatar_data BYTEA,
    avatar_emoji TEXT,
    avatar_initials TEXT,
    avatar_color_index INTEGER DEFAULT 0,

    -- Contact integration
    contact_id TEXT,
    preferred_payment_method payment_method,

    -- Notification preferences
    notification_preferences JSONB DEFAULT '{
        "enable_reminders": true,
        "reminder_frequency": 7,
        "preferred_contact_method": "in_app"
    }'::jsonb,

    -- Relationship
    relationship_type TEXT,
    notes TEXT,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL
);

-- Indexes for persons
CREATE INDEX idx_persons_user_id ON persons(user_id);
CREATE INDEX idx_persons_email ON persons(email) WHERE email IS NOT NULL;
CREATE INDEX idx_persons_contact_id ON persons(contact_id) WHERE contact_id IS NOT NULL;
CREATE INDEX idx_persons_deleted_at ON persons(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_persons_balance ON persons(user_id, balance) WHERE balance != 0;

-- ============================================================
-- SECTION 6: ACCOUNTS TABLE
-- Bank accounts, cards, wallets
-- ============================================================

CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    number TEXT,
    type account_type NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL
);

-- Indexes for accounts
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_accounts_default ON accounts(user_id, is_default) WHERE is_default = TRUE;
CREATE INDEX idx_accounts_deleted_at ON accounts(deleted_at) WHERE deleted_at IS NULL;

-- Ensure only one default account per user
CREATE UNIQUE INDEX idx_accounts_single_default
ON accounts(user_id)
WHERE is_default = TRUE AND deleted_at IS NULL;

-- ============================================================
-- SECTION 7: GROUPS TABLE
-- Groups for shared expenses
-- ============================================================

CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    description TEXT,
    emoji TEXT DEFAULT '👥',
    total_amount DECIMAL(15, 2) DEFAULT 0.00 NOT NULL,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL
);

-- Indexes for groups
CREATE INDEX idx_groups_user_id ON groups(user_id);
CREATE INDEX idx_groups_deleted_at ON groups(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- SECTION 8: GROUP MEMBERS TABLE (Junction)
-- Links groups to persons and users
-- ============================================================

CREATE TABLE group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,

    -- Can be either a person (local contact) or a user (Supabase user)
    person_id UUID REFERENCES persons(id) ON DELETE CASCADE,
    member_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,

    -- Member role
    is_admin BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

    -- For invited users
    invitation_status invitation_status DEFAULT 'accepted',
    invited_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL,

    -- Either person_id OR member_user_id must be set
    CONSTRAINT member_reference CHECK (
        (person_id IS NOT NULL AND member_user_id IS NULL) OR
        (person_id IS NULL AND member_user_id IS NOT NULL)
    )
);

-- Indexes for group_members
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_person_id ON group_members(person_id) WHERE person_id IS NOT NULL;
CREATE INDEX idx_group_members_user_id ON group_members(member_user_id) WHERE member_user_id IS NOT NULL;
CREATE INDEX idx_group_members_deleted_at ON group_members(deleted_at) WHERE deleted_at IS NULL;

-- Unique constraint: a member can only be in a group once
CREATE UNIQUE INDEX idx_group_members_unique_person
ON group_members(group_id, person_id)
WHERE person_id IS NOT NULL AND deleted_at IS NULL;

CREATE UNIQUE INDEX idx_group_members_unique_user
ON group_members(group_id, member_user_id)
WHERE member_user_id IS NOT NULL AND deleted_at IS NULL;

-- ============================================================
-- SECTION 9: GROUP EXPENSES TABLE
-- Expenses within groups
-- ============================================================

CREATE TABLE group_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    paid_by_person_id UUID REFERENCES persons(id),
    paid_by_user_id UUID REFERENCES user_profiles(id),

    -- Split information
    split_between_person_ids UUID[] DEFAULT '{}',
    split_between_user_ids UUID[] DEFAULT '{}',

    category transaction_category NOT NULL DEFAULT 'other',
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT,
    receipt_path TEXT,
    is_settled BOOLEAN DEFAULT FALSE,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL,

    -- Payer must be specified
    CONSTRAINT payer_reference CHECK (
        paid_by_person_id IS NOT NULL OR paid_by_user_id IS NOT NULL
    )
);

-- Indexes for group_expenses
CREATE INDEX idx_group_expenses_group_id ON group_expenses(group_id);
CREATE INDEX idx_group_expenses_date ON group_expenses(group_id, date DESC);
CREATE INDEX idx_group_expenses_settled ON group_expenses(group_id, is_settled);
CREATE INDEX idx_group_expenses_deleted_at ON group_expenses(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- SECTION 10: SUBSCRIPTIONS TABLE
-- User's subscriptions with all tracking fields
-- ============================================================

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

    -- Basic info
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(15, 2) NOT NULL,
    billing_cycle billing_cycle NOT NULL,
    category subscription_category NOT NULL DEFAULT 'other',

    -- Display
    icon TEXT DEFAULT 'app.fill',
    color TEXT DEFAULT '#007AFF',

    -- Status
    next_billing_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    is_shared BOOLEAN DEFAULT FALSE,
    payment_method payment_method,

    -- Billing history
    last_billing_date TIMESTAMPTZ,
    total_spent DECIMAL(15, 2) DEFAULT 0.00,

    -- Additional info
    notes TEXT,
    website TEXT,
    cancellation_date TIMESTAMPTZ,

    -- Trial fields
    is_free_trial BOOLEAN DEFAULT FALSE,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,
    trial_duration INTEGER,
    will_convert_to_paid BOOLEAN DEFAULT TRUE,
    price_after_trial DECIMAL(15, 2),

    -- Reminder fields
    enable_renewal_reminder BOOLEAN DEFAULT TRUE,
    reminder_days_before INTEGER DEFAULT 3,
    reminder_time TIMESTAMPTZ,
    last_reminder_sent TIMESTAMPTZ,

    -- Usage tracking
    last_used_date TIMESTAMPTZ,
    usage_count INTEGER DEFAULT 0,

    -- Price history
    last_price_change TIMESTAMPTZ,

    -- Cancellation info
    auto_renew BOOLEAN DEFAULT TRUE,
    cancellation_deadline TIMESTAMPTZ,
    cancellation_instructions TEXT,
    cancellation_difficulty cancellation_difficulty,

    -- JSONB fields for complex data
    alternative_suggestions JSONB DEFAULT '[]'::jsonb,
    retention_offers JSONB DEFAULT '[]'::jsonb,
    documents JSONB DEFAULT '[]'::jsonb,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL
);

-- Indexes for subscriptions
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_active ON subscriptions(user_id, is_active);
CREATE INDEX idx_subscriptions_next_billing ON subscriptions(user_id, next_billing_date);
CREATE INDEX idx_subscriptions_category ON subscriptions(user_id, category);
CREATE INDEX idx_subscriptions_trial ON subscriptions(user_id, is_free_trial, trial_end_date)
    WHERE is_free_trial = TRUE;
CREATE INDEX idx_subscriptions_deleted_at ON subscriptions(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- SECTION 11: SHARED SUBSCRIPTIONS TABLE
-- Subscriptions shared between users
-- ============================================================

CREATE TABLE shared_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    shared_by_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

    -- Who it's shared with
    shared_with_person_id UUID REFERENCES persons(id) ON DELETE CASCADE,
    shared_with_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,

    -- Split details
    cost_split_type cost_split_type NOT NULL DEFAULT 'equal',
    individual_cost DECIMAL(15, 2),
    percentage DECIMAL(5, 2),

    -- Status
    is_accepted BOOLEAN DEFAULT FALSE,
    invitation_status invitation_status DEFAULT 'pending',

    notes TEXT,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL,

    -- Must be shared with someone
    CONSTRAINT share_target CHECK (
        shared_with_person_id IS NOT NULL OR shared_with_user_id IS NOT NULL
    )
);

-- Indexes for shared_subscriptions
CREATE INDEX idx_shared_subscriptions_subscription ON shared_subscriptions(subscription_id);
CREATE INDEX idx_shared_subscriptions_shared_by ON shared_subscriptions(shared_by_user_id);
CREATE INDEX idx_shared_subscriptions_shared_with_person ON shared_subscriptions(shared_with_person_id)
    WHERE shared_with_person_id IS NOT NULL;
CREATE INDEX idx_shared_subscriptions_shared_with_user ON shared_subscriptions(shared_with_user_id)
    WHERE shared_with_user_id IS NOT NULL;
CREATE INDEX idx_shared_subscriptions_status ON shared_subscriptions(invitation_status);
CREATE INDEX idx_shared_subscriptions_deleted_at ON shared_subscriptions(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- SECTION 12: PRICE CHANGES TABLE
-- Subscription price history tracking
-- ============================================================

CREATE TABLE price_changes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,

    old_price DECIMAL(15, 2) NOT NULL,
    new_price DECIMAL(15, 2) NOT NULL,
    change_date TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    reason TEXT,
    detected_automatically BOOLEAN DEFAULT FALSE,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL
);

-- Indexes for price_changes
CREATE INDEX idx_price_changes_subscription ON price_changes(subscription_id);
CREATE INDEX idx_price_changes_date ON price_changes(subscription_id, change_date DESC);
CREATE INDEX idx_price_changes_deleted_at ON price_changes(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- SECTION 13: SUBSCRIPTION EVENTS TABLE
-- Timeline events for subscriptions
-- ============================================================

CREATE TABLE subscription_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,

    event_type subscription_event_type NOT NULL,
    event_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    title TEXT NOT NULL,
    subtitle TEXT,
    amount DECIMAL(15, 2),

    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    is_system_message BOOLEAN DEFAULT FALSE,
    related_person_id UUID REFERENCES persons(id),

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL
);

-- Indexes for subscription_events
CREATE INDEX idx_subscription_events_subscription ON subscription_events(subscription_id);
CREATE INDEX idx_subscription_events_date ON subscription_events(subscription_id, event_date DESC);
CREATE INDEX idx_subscription_events_type ON subscription_events(subscription_id, event_type);
CREATE INDEX idx_subscription_events_deleted_at ON subscription_events(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- SECTION 14: TRANSACTIONS TABLE
-- Financial transactions
-- ============================================================

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

    -- Basic info
    title TEXT NOT NULL,
    subtitle TEXT,
    amount DECIMAL(15, 2) NOT NULL,
    category transaction_category NOT NULL DEFAULT 'other',
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Transaction type
    transaction_type transaction_type,
    is_recurring BOOLEAN DEFAULT FALSE,
    is_recurring_charge BOOLEAN DEFAULT FALSE,

    -- Tags
    tags TEXT[] DEFAULT '{}',

    -- Merchant info
    merchant TEXT,
    merchant_category TEXT,

    -- Status
    payment_status payment_status DEFAULT 'completed',

    -- Receipt
    receipt_data BYTEA,

    -- Linked entities
    linked_subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    split_bill_id UUID,
    related_person_id UUID REFERENCES persons(id) ON DELETE SET NULL,

    -- Payment
    payment_method payment_method,
    account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,

    -- Location and notes
    location TEXT,
    notes TEXT,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL
);

-- Indexes for transactions
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_date ON transactions(user_id, date DESC);
CREATE INDEX idx_transactions_category ON transactions(user_id, category);
CREATE INDEX idx_transactions_type ON transactions(user_id, transaction_type);
CREATE INDEX idx_transactions_status ON transactions(user_id, payment_status);
CREATE INDEX idx_transactions_subscription ON transactions(linked_subscription_id)
    WHERE linked_subscription_id IS NOT NULL;
CREATE INDEX idx_transactions_person ON transactions(related_person_id)
    WHERE related_person_id IS NOT NULL;
CREATE INDEX idx_transactions_split_bill ON transactions(split_bill_id)
    WHERE split_bill_id IS NOT NULL;
CREATE INDEX idx_transactions_recurring ON transactions(user_id, is_recurring)
    WHERE is_recurring = TRUE;
CREATE INDEX idx_transactions_deleted_at ON transactions(deleted_at) WHERE deleted_at IS NULL;

-- GIN index for tags array search
CREATE INDEX idx_transactions_tags ON transactions USING GIN(tags);

-- ============================================================
-- SECTION 15: SPLIT BILLS TABLE
-- Bill splitting records
-- ============================================================

CREATE TABLE split_bills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,

    -- Who paid
    paid_by_person_id UUID REFERENCES persons(id),
    paid_by_user_id UUID REFERENCES user_profiles(id),

    split_type split_type NOT NULL DEFAULT 'equally',

    notes TEXT,
    category transaction_category NOT NULL DEFAULT 'dining',
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Optional group association
    group_id UUID REFERENCES groups(id) ON DELETE SET NULL,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL,

    -- Payer must be specified
    CONSTRAINT split_payer_reference CHECK (
        paid_by_person_id IS NOT NULL OR paid_by_user_id IS NOT NULL
    )
);

-- Add FK constraint to transactions
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_split_bill
FOREIGN KEY (split_bill_id) REFERENCES split_bills(id) ON DELETE SET NULL;

-- Indexes for split_bills
CREATE INDEX idx_split_bills_user_id ON split_bills(user_id);
CREATE INDEX idx_split_bills_date ON split_bills(user_id, date DESC);
CREATE INDEX idx_split_bills_group ON split_bills(group_id) WHERE group_id IS NOT NULL;
CREATE INDEX idx_split_bills_deleted_at ON split_bills(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- SECTION 16: SPLIT PARTICIPANTS TABLE
-- Participants in split bills
-- ============================================================

CREATE TABLE split_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    split_bill_id UUID NOT NULL REFERENCES split_bills(id) ON DELETE CASCADE,

    -- Can be person or user
    person_id UUID REFERENCES persons(id) ON DELETE CASCADE,
    participant_user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,

    amount DECIMAL(15, 2) NOT NULL,
    has_paid BOOLEAN DEFAULT FALSE,
    payment_date TIMESTAMPTZ,

    -- For different split types
    percentage DECIMAL(5, 2),
    shares INTEGER,

    -- Timestamps and sync
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    deleted_at TIMESTAMPTZ,
    sync_version INTEGER DEFAULT 1 NOT NULL,

    -- Participant must be specified
    CONSTRAINT participant_reference CHECK (
        person_id IS NOT NULL OR participant_user_id IS NOT NULL
    )
);

-- Indexes for split_participants
CREATE INDEX idx_split_participants_bill ON split_participants(split_bill_id);
CREATE INDEX idx_split_participants_person ON split_participants(person_id)
    WHERE person_id IS NOT NULL;
CREATE INDEX idx_split_participants_user ON split_participants(participant_user_id)
    WHERE participant_user_id IS NOT NULL;
CREATE INDEX idx_split_participants_unpaid ON split_participants(split_bill_id, has_paid)
    WHERE has_paid = FALSE;
CREATE INDEX idx_split_participants_deleted_at ON split_participants(deleted_at) WHERE deleted_at IS NULL;

-- ============================================================
-- SECTION 17: INVITATIONS TABLE
-- Multi-user collaboration invitations
-- ============================================================

CREATE TABLE invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Inviter
    inviter_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

    -- Invitee
    invitee_email TEXT NOT NULL,
    invitee_user_id UUID REFERENCES user_profiles(id),

    -- What is being shared
    invitation_type TEXT NOT NULL,
    resource_id UUID NOT NULL,

    -- Status
    status invitation_status DEFAULT 'pending',

    -- Token for invitation link
    token TEXT UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    responded_at TIMESTAMPTZ
);

-- Indexes for invitations
CREATE INDEX idx_invitations_inviter ON invitations(inviter_user_id);
CREATE INDEX idx_invitations_invitee_email ON invitations(invitee_email);
CREATE INDEX idx_invitations_invitee_user ON invitations(invitee_user_id)
    WHERE invitee_user_id IS NOT NULL;
CREATE INDEX idx_invitations_token ON invitations(token);
CREATE INDEX idx_invitations_status ON invitations(status);
CREATE INDEX idx_invitations_resource ON invitations(invitation_type, resource_id);

-- ============================================================
-- SECTION 18: TRIGGERS
-- Auto-update timestamps and sync versions
-- ============================================================

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_persons_updated_at
    BEFORE UPDATE ON persons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_groups_updated_at
    BEFORE UPDATE ON groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_group_members_updated_at
    BEFORE UPDATE ON group_members
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_group_expenses_updated_at
    BEFORE UPDATE ON group_expenses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shared_subscriptions_updated_at
    BEFORE UPDATE ON shared_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_price_changes_updated_at
    BEFORE UPDATE ON price_changes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscription_events_updated_at
    BEFORE UPDATE ON subscription_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_split_bills_updated_at
    BEFORE UPDATE ON split_bills
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_split_participants_updated_at
    BEFORE UPDATE ON split_participants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- SECTION 19: ROW LEVEL SECURITY (RLS) - ENABLE
-- Enable RLS on all tables
-- ============================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE split_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE split_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 20: RLS POLICIES - USER PROFILES
-- ============================================================

CREATE POLICY "Users can view own profile"
    ON user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Allow viewing profiles of connected users
CREATE POLICY "Users can view connected profiles"
    ON user_profiles FOR SELECT
    USING (
        id IN (
            SELECT gm2.member_user_id FROM group_members gm1
            JOIN group_members gm2 ON gm1.group_id = gm2.group_id
            WHERE gm1.member_user_id = auth.uid()
            AND gm2.member_user_id IS NOT NULL
        )
        OR
        id IN (
            SELECT shared_with_user_id FROM shared_subscriptions
            WHERE shared_by_user_id = auth.uid()
            UNION
            SELECT shared_by_user_id FROM shared_subscriptions
            WHERE shared_with_user_id = auth.uid()
        )
    );

-- ============================================================
-- SECTION 21: RLS POLICIES - PERSONS
-- ============================================================

CREATE POLICY "Users can view own persons"
    ON persons FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own persons"
    ON persons FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own persons"
    ON persons FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete own persons"
    ON persons FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================
-- SECTION 22: RLS POLICIES - ACCOUNTS
-- ============================================================

CREATE POLICY "Users can view own accounts"
    ON accounts FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own accounts"
    ON accounts FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own accounts"
    ON accounts FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete own accounts"
    ON accounts FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================
-- SECTION 23: RLS POLICIES - GROUPS
-- ============================================================

CREATE POLICY "Users can view groups they own or are members of"
    ON groups FOR SELECT
    USING (
        user_id = auth.uid()
        OR id IN (
            SELECT group_id FROM group_members
            WHERE member_user_id = auth.uid()
            AND deleted_at IS NULL
        )
    );

CREATE POLICY "Users can create groups"
    ON groups FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Owners can update groups"
    ON groups FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Owners can delete groups"
    ON groups FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================
-- SECTION 24: RLS POLICIES - GROUP MEMBERS
-- ============================================================

CREATE POLICY "Users can view members of their groups"
    ON group_members FOR SELECT
    USING (
        group_id IN (
            SELECT id FROM groups WHERE user_id = auth.uid()
            UNION
            SELECT group_id FROM group_members WHERE member_user_id = auth.uid()
        )
    );

CREATE POLICY "Group owners can insert members"
    ON group_members FOR INSERT
    WITH CHECK (
        group_id IN (SELECT id FROM groups WHERE user_id = auth.uid())
    );

CREATE POLICY "Group owners can update members"
    ON group_members FOR UPDATE
    USING (
        group_id IN (SELECT id FROM groups WHERE user_id = auth.uid())
    );

CREATE POLICY "Group owners can delete members"
    ON group_members FOR DELETE
    USING (
        group_id IN (SELECT id FROM groups WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can leave groups"
    ON group_members FOR DELETE
    USING (member_user_id = auth.uid());

-- ============================================================
-- SECTION 25: RLS POLICIES - GROUP EXPENSES
-- ============================================================

CREATE POLICY "Users can view expenses of their groups"
    ON group_expenses FOR SELECT
    USING (
        group_id IN (
            SELECT id FROM groups WHERE user_id = auth.uid()
            UNION
            SELECT group_id FROM group_members WHERE member_user_id = auth.uid()
        )
    );

CREATE POLICY "Group members can create expenses"
    ON group_expenses FOR INSERT
    WITH CHECK (
        group_id IN (
            SELECT id FROM groups WHERE user_id = auth.uid()
            UNION
            SELECT group_id FROM group_members WHERE member_user_id = auth.uid()
        )
    );

CREATE POLICY "Expense creators and group owners can update"
    ON group_expenses FOR UPDATE
    USING (
        paid_by_user_id = auth.uid()
        OR group_id IN (SELECT id FROM groups WHERE user_id = auth.uid())
    );

CREATE POLICY "Expense creators and group owners can delete"
    ON group_expenses FOR DELETE
    USING (
        paid_by_user_id = auth.uid()
        OR group_id IN (SELECT id FROM groups WHERE user_id = auth.uid())
    );

-- ============================================================
-- SECTION 26: RLS POLICIES - SUBSCRIPTIONS
-- ============================================================

CREATE POLICY "Users can view own subscriptions"
    ON subscriptions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can view subscriptions shared with them"
    ON subscriptions FOR SELECT
    USING (
        id IN (
            SELECT subscription_id FROM shared_subscriptions
            WHERE shared_with_user_id = auth.uid()
            AND is_accepted = TRUE
        )
    );

CREATE POLICY "Users can insert own subscriptions"
    ON subscriptions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own subscriptions"
    ON subscriptions FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete own subscriptions"
    ON subscriptions FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================
-- SECTION 27: RLS POLICIES - SHARED SUBSCRIPTIONS
-- ============================================================

CREATE POLICY "Users can view shared subscriptions involving them"
    ON shared_subscriptions FOR SELECT
    USING (
        shared_by_user_id = auth.uid()
        OR shared_with_user_id = auth.uid()
    );

CREATE POLICY "Subscription owners can share"
    ON shared_subscriptions FOR INSERT
    WITH CHECK (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

CREATE POLICY "Owners can update shared subscriptions"
    ON shared_subscriptions FOR UPDATE
    USING (shared_by_user_id = auth.uid());

CREATE POLICY "Invitees can accept or decline"
    ON shared_subscriptions FOR UPDATE
    USING (shared_with_user_id = auth.uid());

CREATE POLICY "Owners can delete shared subscriptions"
    ON shared_subscriptions FOR DELETE
    USING (shared_by_user_id = auth.uid());

-- ============================================================
-- SECTION 28: RLS POLICIES - PRICE CHANGES
-- ============================================================

CREATE POLICY "Users can view price changes of own subscriptions"
    ON price_changes FOR SELECT
    USING (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert price changes for own subscriptions"
    ON price_changes FOR INSERT
    WITH CHECK (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update price changes of own subscriptions"
    ON price_changes FOR UPDATE
    USING (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can delete price changes of own subscriptions"
    ON price_changes FOR DELETE
    USING (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

-- ============================================================
-- SECTION 29: RLS POLICIES - SUBSCRIPTION EVENTS
-- ============================================================

CREATE POLICY "Users can view events of own subscriptions"
    ON subscription_events FOR SELECT
    USING (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert events for own subscriptions"
    ON subscription_events FOR INSERT
    WITH CHECK (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update events of own subscriptions"
    ON subscription_events FOR UPDATE
    USING (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can delete events of own subscriptions"
    ON subscription_events FOR DELETE
    USING (
        subscription_id IN (SELECT id FROM subscriptions WHERE user_id = auth.uid())
    );

-- ============================================================
-- SECTION 30: RLS POLICIES - TRANSACTIONS
-- ============================================================

CREATE POLICY "Users can view own transactions"
    ON transactions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own transactions"
    ON transactions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own transactions"
    ON transactions FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete own transactions"
    ON transactions FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================
-- SECTION 31: RLS POLICIES - SPLIT BILLS
-- ============================================================

CREATE POLICY "Users can view own split bills"
    ON split_bills FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can view split bills they participate in"
    ON split_bills FOR SELECT
    USING (
        id IN (
            SELECT split_bill_id FROM split_participants
            WHERE participant_user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own split bills"
    ON split_bills FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own split bills"
    ON split_bills FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete own split bills"
    ON split_bills FOR DELETE
    USING (user_id = auth.uid());

-- ============================================================
-- SECTION 32: RLS POLICIES - SPLIT PARTICIPANTS
-- ============================================================

CREATE POLICY "Users can view participants of their split bills"
    ON split_participants FOR SELECT
    USING (
        split_bill_id IN (SELECT id FROM split_bills WHERE user_id = auth.uid())
        OR participant_user_id = auth.uid()
    );

CREATE POLICY "Split bill owners can insert participants"
    ON split_participants FOR INSERT
    WITH CHECK (
        split_bill_id IN (SELECT id FROM split_bills WHERE user_id = auth.uid())
    );

CREATE POLICY "Split bill owners can update participants"
    ON split_participants FOR UPDATE
    USING (
        split_bill_id IN (SELECT id FROM split_bills WHERE user_id = auth.uid())
    );

CREATE POLICY "Participants can update their own payment status"
    ON split_participants FOR UPDATE
    USING (participant_user_id = auth.uid());

CREATE POLICY "Split bill owners can delete participants"
    ON split_participants FOR DELETE
    USING (
        split_bill_id IN (SELECT id FROM split_bills WHERE user_id = auth.uid())
    );

-- ============================================================
-- SECTION 33: RLS POLICIES - INVITATIONS
-- ============================================================

CREATE POLICY "Inviters can view their invitations"
    ON invitations FOR SELECT
    USING (inviter_user_id = auth.uid());

CREATE POLICY "Invitees can view invitations sent to them"
    ON invitations FOR SELECT
    USING (
        invitee_user_id = auth.uid()
        OR invitee_email = (SELECT email FROM user_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Users can create invitations"
    ON invitations FOR INSERT
    WITH CHECK (inviter_user_id = auth.uid());

CREATE POLICY "Inviters can update their invitations"
    ON invitations FOR UPDATE
    USING (inviter_user_id = auth.uid());

CREATE POLICY "Invitees can respond to invitations"
    ON invitations FOR UPDATE
    USING (
        invitee_user_id = auth.uid()
        OR invitee_email = (SELECT email FROM user_profiles WHERE id = auth.uid())
    );

CREATE POLICY "Inviters can delete their invitations"
    ON invitations FOR DELETE
    USING (inviter_user_id = auth.uid());

-- ============================================================
-- SECTION 34: REALTIME CONFIGURATION
-- Enable realtime for key tables
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE user_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE persons;
ALTER PUBLICATION supabase_realtime ADD TABLE groups;
ALTER PUBLICATION supabase_realtime ADD TABLE group_members;
ALTER PUBLICATION supabase_realtime ADD TABLE group_expenses;
ALTER PUBLICATION supabase_realtime ADD TABLE subscriptions;
ALTER PUBLICATION supabase_realtime ADD TABLE shared_subscriptions;
ALTER PUBLICATION supabase_realtime ADD TABLE transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE split_bills;
ALTER PUBLICATION supabase_realtime ADD TABLE split_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE invitations;

-- ============================================================
-- SECTION 35: HELPER VIEWS
-- Useful views for common queries
-- ============================================================

-- View for subscription with sharing status
CREATE OR REPLACE VIEW subscriptions_with_shares AS
SELECT
    s.*,
    COALESCE(
        (SELECT json_agg(json_build_object(
            'id', ss.id,
            'shared_with_user_id', ss.shared_with_user_id,
            'shared_with_person_id', ss.shared_with_person_id,
            'cost_split_type', ss.cost_split_type,
            'individual_cost', ss.individual_cost,
            'is_accepted', ss.is_accepted
        ))
        FROM shared_subscriptions ss
        WHERE ss.subscription_id = s.id AND ss.deleted_at IS NULL),
        '[]'::json
    ) as shares
FROM subscriptions s
WHERE s.deleted_at IS NULL;

-- View for group member balances
CREATE OR REPLACE VIEW group_member_balances AS
SELECT
    gm.group_id,
    gm.id as member_id,
    gm.person_id,
    gm.member_user_id,
    COALESCE(p.name, up.name) as member_name,
    COALESCE(
        (SELECT SUM(ge.amount / NULLIF(array_length(
            CASE
                WHEN gm.person_id IS NOT NULL THEN ge.split_between_person_ids
                ELSE ge.split_between_user_ids
            END, 1), 0))
         FROM group_expenses ge
         WHERE ge.group_id = gm.group_id
         AND ge.deleted_at IS NULL
         AND (
             (gm.person_id IS NOT NULL AND gm.person_id = ANY(ge.split_between_person_ids))
             OR
             (gm.member_user_id IS NOT NULL AND gm.member_user_id = ANY(ge.split_between_user_ids))
         )
        ), 0
    ) as total_owed,
    COALESCE(
        (SELECT SUM(ge.amount)
         FROM group_expenses ge
         WHERE ge.group_id = gm.group_id
         AND ge.deleted_at IS NULL
         AND (
             (gm.person_id IS NOT NULL AND ge.paid_by_person_id = gm.person_id)
             OR
             (gm.member_user_id IS NOT NULL AND ge.paid_by_user_id = gm.member_user_id)
         )
        ), 0
    ) as total_paid
FROM group_members gm
LEFT JOIN persons p ON gm.person_id = p.id
LEFT JOIN user_profiles up ON gm.member_user_id = up.id
WHERE gm.deleted_at IS NULL;

-- ============================================================
-- SCHEMA COMPLETE!
--
-- Summary:
-- - 14 Tables created
-- - 14 Enum types created
-- - 50+ Indexes created
-- - 40+ RLS Policies created
-- - 13 Triggers created
-- - 2 Helper views created
-- - Realtime enabled on 11 tables
-- ============================================================
