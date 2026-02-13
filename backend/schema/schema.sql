-- =====================================================
-- Flutter Kenya Community Platform - Chat System Schema
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLES
-- =====================================================

-- Channels (Group Channels)
CREATE TABLE channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    avatar_url TEXT,
    channel_type VARCHAR(20) DEFAULT 'public' CHECK (channel_type IN ('public', 'private')),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_archived BOOLEAN DEFAULT FALSE,
    member_count INTEGER DEFAULT 0
);

-- Channel Members
CREATE TABLE channel_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID REFERENCES channels(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notifications_enabled BOOLEAN DEFAULT TRUE,
    UNIQUE(channel_id, user_id)
);

-- Messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID REFERENCES channels(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    content TEXT,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    parent_message_id UUID REFERENCES messages(id) ON DELETE CASCADE, -- For threads
    thread_count INTEGER DEFAULT 0, -- Number of replies in thread
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Message Attachments (for media sharing)
CREATE TABLE message_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50) NOT NULL, -- 'image/png', 'application/pdf', etc.
    file_size BIGINT NOT NULL, -- in bytes
    thumbnail_url TEXT, -- For images/videos
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Message Reactions
CREATE TABLE message_reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    emoji VARCHAR(10) NOT NULL, -- Store emoji as unicode
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(message_id, user_id, emoji)
);

-- Typing Indicators (ephemeral data, auto-cleanup after 10 seconds)
CREATE TABLE typing_indicators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_id UUID REFERENCES channels(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(channel_id, user_id)
);

-- User Profiles (extend auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    flutter_experience VARCHAR(50),
    location VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_online BOOLEAN DEFAULT FALSE
);

-- Push Notification Tokens
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Channel indexes
CREATE INDEX idx_channels_created_by ON channels(created_by);
CREATE INDEX idx_channels_type ON channels(channel_type);
CREATE INDEX idx_channels_archived ON channels(is_archived);

-- Channel members indexes
CREATE INDEX idx_channel_members_channel ON channel_members(channel_id);
CREATE INDEX idx_channel_members_user ON channel_members(user_id);
CREATE INDEX idx_channel_members_last_read ON channel_members(channel_id, last_read_at);

-- Messages indexes
CREATE INDEX idx_messages_channel ON messages(channel_id, created_at DESC);
CREATE INDEX idx_messages_user ON messages(user_id);
CREATE INDEX idx_messages_parent ON messages(parent_message_id) WHERE parent_message_id IS NOT NULL;
CREATE INDEX idx_messages_thread ON messages(channel_id, parent_message_id, created_at) WHERE parent_message_id IS NOT NULL;

-- Message attachments indexes
CREATE INDEX idx_attachments_message ON message_attachments(message_id);

-- Reactions indexes
CREATE INDEX idx_reactions_message ON message_reactions(message_id);
CREATE INDEX idx_reactions_user ON message_reactions(user_id);

-- Typing indicators indexes
CREATE INDEX idx_typing_channel ON typing_indicators(channel_id);

-- Profiles indexes
CREATE INDEX idx_profiles_online ON profiles(is_online);

-- Push tokens indexes
CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_channels_updated_at BEFORE UPDATE ON channels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update channel member count
CREATE OR REPLACE FUNCTION update_channel_member_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE channels SET member_count = member_count + 1 WHERE id = NEW.channel_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE channels SET member_count = member_count - 1 WHERE id = OLD.channel_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_member_count_on_join AFTER INSERT ON channel_members
    FOR EACH ROW EXECUTE FUNCTION update_channel_member_count();

CREATE TRIGGER update_member_count_on_leave AFTER DELETE ON channel_members
    FOR EACH ROW EXECUTE FUNCTION update_channel_member_count();

-- Update thread count
CREATE OR REPLACE FUNCTION update_thread_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.parent_message_id IS NOT NULL THEN
        UPDATE messages SET thread_count = thread_count + 1 WHERE id = NEW.parent_message_id;
    ELSIF TG_OP = 'DELETE' AND OLD.parent_message_id IS NOT NULL THEN
        UPDATE messages SET thread_count = thread_count - 1 WHERE id = OLD.parent_message_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_thread_count_on_reply AFTER INSERT OR DELETE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_thread_count();

-- Auto-cleanup typing indicators older than 10 seconds
CREATE OR REPLACE FUNCTION cleanup_old_typing_indicators()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM typing_indicators 
    WHERE started_at < NOW() - INTERVAL '10 seconds';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cleanup_typing_indicators AFTER INSERT ON typing_indicators
    EXECUTE FUNCTION cleanup_old_typing_indicators();

-- Mark message as edited
CREATE OR REPLACE FUNCTION mark_message_edited()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.content IS DISTINCT FROM NEW.content THEN
        NEW.is_edited = TRUE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mark_edited_on_update BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION mark_message_edited();

-- Update last_seen_at on profile activity
CREATE OR REPLACE FUNCTION update_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE profiles SET last_seen_at = NOW() WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_last_seen_on_message AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_last_seen();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE channel_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- Channels Policies
CREATE POLICY "Public channels are viewable by everyone"
    ON channels FOR SELECT
    USING (channel_type = 'public' AND is_archived = FALSE);

CREATE POLICY "Private channels viewable by members"
    ON channels FOR SELECT
    USING (
        channel_type = 'private' AND 
        id IN (SELECT channel_id FROM channel_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Admins can create channels"
    ON channels FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Channel creators and admins can update"
    ON channels FOR UPDATE
    USING (
        created_by = auth.uid() OR 
        id IN (SELECT channel_id FROM channel_members WHERE user_id = auth.uid() AND role = 'admin')
    );

-- Channel Members Policies
CREATE POLICY "Users can view channel members"
    ON channel_members FOR SELECT
    USING (
        channel_id IN (SELECT channel_id FROM channel_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can join public channels"
    ON channel_members FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        channel_id IN (SELECT id FROM channels WHERE channel_type = 'public')
    );

CREATE POLICY "Users can leave channels"
    ON channel_members FOR DELETE
    USING (user_id = auth.uid());

CREATE POLICY "Users can update their own membership"
    ON channel_members FOR UPDATE
    USING (user_id = auth.uid());

-- Messages Policies
CREATE POLICY "Users can view messages in their channels"
    ON messages FOR SELECT
    USING (
        channel_id IN (SELECT channel_id FROM channel_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can send messages to their channels"
    ON messages FOR INSERT
    WITH CHECK (
        user_id = auth.uid() AND
        channel_id IN (SELECT channel_id FROM channel_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update their own messages"
    ON messages FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own messages"
    ON messages FOR DELETE
    USING (user_id = auth.uid());

-- Message Attachments Policies
CREATE POLICY "Users can view attachments in their channels"
    ON message_attachments FOR SELECT
    USING (
        message_id IN (
            SELECT id FROM messages WHERE channel_id IN (
                SELECT channel_id FROM channel_members WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can upload attachments to their messages"
    ON message_attachments FOR INSERT
    WITH CHECK (
        message_id IN (SELECT id FROM messages WHERE user_id = auth.uid())
    );

-- Message Reactions Policies
CREATE POLICY "Users can view reactions in their channels"
    ON message_reactions FOR SELECT
    USING (
        message_id IN (
            SELECT id FROM messages WHERE channel_id IN (
                SELECT channel_id FROM channel_members WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can add reactions"
    ON message_reactions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can remove their own reactions"
    ON message_reactions FOR DELETE
    USING (user_id = auth.uid());

-- Typing Indicators Policies
CREATE POLICY "Users can view typing indicators in their channels"
    ON typing_indicators FOR SELECT
    USING (
        channel_id IN (SELECT channel_id FROM channel_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can add their own typing indicators"
    ON typing_indicators FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own typing indicators"
    ON typing_indicators FOR DELETE
    USING (user_id = auth.uid());

-- Profiles Policies
CREATE POLICY "Profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (id = auth.uid());

CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    WITH CHECK (id = auth.uid());

-- Push Tokens Policies
CREATE POLICY "Users can manage their own push tokens"
    ON push_tokens FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for messages with user info and reaction counts
CREATE OR REPLACE VIEW messages_with_details AS
SELECT 
    m.id,
    m.channel_id,
    m.user_id,
    m.content,
    m.message_type,
    m.parent_message_id,
    m.thread_count,
    m.created_at,
    m.updated_at,
    m.is_edited,
    m.is_deleted,
    p.full_name as user_name,
    p.avatar_url as user_avatar,
    (SELECT COUNT(*) FROM message_reactions WHERE message_id = m.id) as reaction_count,
    (SELECT json_agg(json_build_object('id', id, 'file_url', file_url, 'file_type', file_type, 'file_name', file_name))
     FROM message_attachments WHERE message_id = m.id) as attachments
FROM messages m
LEFT JOIN profiles p ON m.user_id = p.id
WHERE m.is_deleted = FALSE;

-- View for channels with unread count
CREATE OR REPLACE VIEW channels_with_unread AS
SELECT 
    c.*,
    cm.last_read_at,
    (SELECT COUNT(*) 
     FROM messages m 
     WHERE m.channel_id = c.id 
     AND m.created_at > cm.last_read_at
     AND m.user_id != cm.user_id) as unread_count
FROM channels c
JOIN channel_members cm ON c.id = cm.channel_id
WHERE cm.user_id = auth.uid();