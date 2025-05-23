PGDMP  '    ,                }            Complex    17.4    17.4 W    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    17618    Complex    DATABASE     o   CREATE DATABASE "Complex" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en-US';
    DROP DATABASE "Complex";
                     postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                     pg_database_owner    false            �           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                        pg_database_owner    false    5            �           1247    18494    change_type    TYPE     x   CREATE TYPE public.change_type AS ENUM (
    'add_member',
    'remove_member',
    'update_info',
    'change_head'
);
    DROP TYPE public.change_type;
       public               postgres    false    5            �           1247    18466    fee_type    TYPE     J   CREATE TYPE public.fee_type AS ENUM (
    'mandatory',
    'voluntary'
);
    DROP TYPE public.fee_type;
       public               postgres    false    5            �           1247    18486    gender    TYPE     M   CREATE TYPE public.gender AS ENUM (
    'Male',
    'Female',
    'Other'
);
    DROP TYPE public.gender;
       public               postgres    false    5            �           1247    18504    notification_type    TYPE     v   CREATE TYPE public.notification_type AS ENUM (
    'fee_reminder',
    'request_status',
    'system_announcement'
);
 $   DROP TYPE public.notification_type;
       public               postgres    false    5            �           1247    18478    payment_method    TYPE     U   CREATE TYPE public.payment_method AS ENUM (
    'qr_code',
    'card',
    'cash'
);
 !   DROP TYPE public.payment_method;
       public               postgres    false    5            �           1247    18472    payment_status    TYPE     H   CREATE TYPE public.payment_status AS ENUM (
    'paid',
    'unpaid'
);
 !   DROP TYPE public.payment_status;
       public               postgres    false    5            �           1247    18460    request_type_enum    TYPE     e   CREATE TYPE public.request_type_enum AS ENUM (
    'temporary_absence',
    'temporary_residence'
);
 $   DROP TYPE public.request_type_enum;
       public               postgres    false    5            �           1247    17667    status    TYPE     D   CREATE TYPE public.status AS ENUM (
    'active',
    'inactive'
);
    DROP TYPE public.status;
       public               postgres    false    5            �           1247    18446    status_account    TYPE     L   CREATE TYPE public.status_account AS ENUM (
    'active',
    'inactive'
);
 !   DROP TYPE public.status_account;
       public               postgres    false    5            �           1247    18452    status_request    TYPE     ]   CREATE TYPE public.status_request AS ENUM (
    'pending',
    'approved',
    'rejected'
);
 !   DROP TYPE public.status_request;
       public               postgres    false    5            �           1247    17620 	   user_role    TYPE     d   CREATE TYPE public.user_role AS ENUM (
    'chu_ho',
    'thu_ky',
    'to_truong',
    'to_pho'
);
    DROP TYPE public.user_role;
       public               postgres    false    5                       1255    18756    create_fee_notifications()    FUNCTION     u  CREATE FUNCTION public.create_fee_notifications() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    household_rec RECORD;
    user_rec RECORD;
BEGIN
    FOR household_rec IN SELECT * FROM households
    LOOP
        SELECT * INTO user_rec FROM users WHERE user_id = household_rec.head_id;
        
        INSERT INTO notifications (
            user_id,
            title,
            content,
            notification_type
        ) VALUES (
            user_rec.user_id,
            'Thông báo phí mới: ' || NEW.title,
            'Kính gửi ' || user_rec.fullname || ', Một khoản phí mới "' || NEW.title || '" với số tiền ' || 
            NEW.amount || ' VND đã được tạo và đến hạn vào ngày ' || NEW.due_date || '. Vui lòng thanh toán đúng hạn.',
            'fee_reminder'
        );
    END LOOP;
    
    RETURN NEW;
END;
$$;
 1   DROP FUNCTION public.create_fee_notifications();
       public               postgres    false    5                       1255    18693    hash()    FUNCTION     N  CREATE FUNCTION public.hash() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NEW.password_hash IS NOT NULL AND position('$' in NEW.password_hash) = 0 THEN
        NEW.password_hash := crypt(NEW.password_hash, gen_salt('bf'));
        NEW.password_last_changed := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$_$;
    DROP FUNCTION public.hash();
       public               postgres    false    5                       1255    18700    log_payment_history()    FUNCTION     �  CREATE FUNCTION public.log_payment_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO payment_history (payment_id, household_id, amount, transaction_id, note, created_at)
    VALUES 
    (
        NEW.payment_id,
        NEW.household_id,
        NEW.amount,
        NEW.transaction_id,
        'Thanh toán đã hoàn thành',
        CURRENT_TIMESTAMP
    );
    RETURN NEW;
END;
$$;
 ,   DROP FUNCTION public.log_payment_history();
       public               postgres    false    5            !           1255    18758    update_household_size()    FUNCTION     �  CREATE FUNCTION public.update_household_size() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    count_members INTEGER;
BEGIN
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
        SELECT COUNT(*) INTO count_members FROM household_members WHERE household_id = NEW.household_id;
        UPDATE households SET household_size = count_members, updated_at = CURRENT_TIMESTAMP WHERE household_id = NEW.household_id;
    ELSIF TG_OP = 'DELETE' THEN
        SELECT COUNT(*) INTO count_members FROM household_members WHERE household_id = OLD.household_id;
        UPDATE households SET household_size = count_members, updated_at = CURRENT_TIMESTAMP WHERE household_id = OLD.household_id;
    END IF;
    RETURN NULL;
END;
$$;
 .   DROP FUNCTION public.update_household_size();
       public               postgres    false    5                       1255    18695 	   updated()    FUNCTION     �   CREATE FUNCTION public.updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;
     DROP FUNCTION public.updated();
       public               postgres    false    5            �            1259    18654    approval_logs    TABLE     �  CREATE TABLE public.approval_logs (
    log_id uuid DEFAULT gen_random_uuid() NOT NULL,
    request_id uuid,
    change_id uuid,
    approved_by uuid NOT NULL,
    action text NOT NULL,
    note text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_request_or_change CHECK ((((request_id IS NOT NULL) AND (change_id IS NULL)) OR ((request_id IS NULL) AND (change_id IS NOT NULL))))
);
 !   DROP TABLE public.approval_logs;
       public         heap r       postgres    false    5            �            1259    18603    fees    TABLE     =  CREATE TABLE public.fees (
    fee_id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text,
    type public.fee_type NOT NULL,
    amount numeric(12,2) NOT NULL,
    due_date date NOT NULL,
    created_by uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.fees;
       public         heap r       postgres    false    922    5            �            1259    18560    household_changes    TABLE     �  CREATE TABLE public.household_changes (
    change_id uuid DEFAULT gen_random_uuid() NOT NULL,
    household_id uuid NOT NULL,
    change_type public.change_type NOT NULL,
    description text NOT NULL,
    requested_by uuid,
    approved_by uuid,
    status public.status_request DEFAULT 'pending'::public.status_request NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 %   DROP TABLE public.household_changes;
       public         heap r       postgres    false    916    934    916    5            �            1259    18542    household_members    TABLE     �  CREATE TABLE public.household_members (
    member_id uuid DEFAULT gen_random_uuid() NOT NULL,
    household_id uuid NOT NULL,
    full_name text NOT NULL,
    gender public.gender NOT NULL,
    other_name text,
    dob date NOT NULL,
    place_of_birth text NOT NULL,
    native_place text NOT NULL,
    ethnic_group text NOT NULL,
    occupation text NOT NULL,
    place_of_work text NOT NULL,
    cccd text NOT NULL,
    issue_date date NOT NULL,
    issued_by text NOT NULL,
    relationship text NOT NULL,
    is_temporary boolean DEFAULT false,
    note text,
    joined_at date DEFAULT CURRENT_DATE NOT NULL,
    CONSTRAINT household_members_cccd_check CHECK ((cccd ~ '^\d{12}$'::text))
);
 %   DROP TABLE public.household_members;
       public         heap r       postgres    false    931    5            �            1259    18524 
   households    TABLE     �  CREATE TABLE public.households (
    household_id uuid DEFAULT gen_random_uuid() NOT NULL,
    household_number text NOT NULL,
    head_id uuid NOT NULL,
    household_size integer NOT NULL,
    address text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT households_household_number_check CHECK ((household_number ~ '^\d{12}$'::text))
);
    DROP TABLE public.households;
       public         heap r       postgres    false    5            �            1259    18685    instructions    TABLE     �   CREATE TABLE public.instructions (
    instruction_id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text,
    content text,
    for_role public.user_role
);
     DROP TABLE public.instructions;
       public         heap r       postgres    false    5    907            �            1259    18669    notifications    TABLE     �  CREATE TABLE public.notifications (
    notification_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    title text NOT NULL,
    content text NOT NULL,
    notification_type public.notification_type NOT NULL,
    is_read boolean DEFAULT false,
    push_sent boolean DEFAULT false,
    push_sent_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 !   DROP TABLE public.notifications;
       public         heap r       postgres    false    937    5            �            1259    18635    payment_history    TABLE       CREATE TABLE public.payment_history (
    history_id uuid DEFAULT gen_random_uuid() NOT NULL,
    payment_id uuid,
    household_id uuid,
    amount numeric(12,2) NOT NULL,
    transaction_id text,
    note text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 #   DROP TABLE public.payment_history;
       public         heap r       postgres    false    5            �            1259    18617    payments    TABLE     @  CREATE TABLE public.payments (
    payment_id uuid DEFAULT gen_random_uuid() NOT NULL,
    fee_id uuid,
    household_id uuid,
    paid_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    method public.payment_method NOT NULL,
    status public.payment_status DEFAULT 'paid'::public.payment_status NOT NULL
);
    DROP TABLE public.payments;
       public         heap r       postgres    false    925    925    5    928            �            1259    18586    residency_requests    TABLE     K  CREATE TABLE public.residency_requests (
    request_id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    request_type public.request_type_enum NOT NULL,
    from_date date NOT NULL,
    to_date date NOT NULL,
    destination text,
    origin text,
    reason text NOT NULL,
    status public.status_request DEFAULT 'pending'::public.status_request NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_date_range CHECK ((from_date <= to_date))
);
 &   DROP TABLE public.residency_requests;
       public         heap r       postgres    false    916    5    919    916            �            1259    18511    users    TABLE     �  CREATE TABLE public.users (
    user_id uuid DEFAULT gen_random_uuid() NOT NULL,
    username text NOT NULL,
    password_hash text NOT NULL,
    role public.user_role NOT NULL,
    fullname text NOT NULL,
    status public.status_account DEFAULT 'inactive'::public.status_account NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.users;
       public         heap r       postgres    false    913    913    5    907            �            1259    18746    view_fee_collection_summary    VIEW       CREATE VIEW public.view_fee_collection_summary AS
SELECT
    NULL::uuid AS fee_id,
    NULL::text AS title,
    NULL::numeric(12,2) AS amount_per_household,
    NULL::bigint AS num_households_paid,
    NULL::numeric AS total_collected,
    NULL::date AS due_date;
 .   DROP VIEW public.view_fee_collection_summary;
       public       v       postgres    false    5            �            1259    18726    view_household_changes_history    VIEW     �  CREATE VIEW public.view_household_changes_history AS
 SELECT c.change_id,
    h.household_id,
    h.address,
    c.change_type,
    c.description,
    req.fullname AS requested_by,
    app.fullname AS approved_by,
    c.status,
    c.created_at,
    c.updated_at
   FROM (((public.household_changes c
     JOIN public.households h ON ((c.household_id = h.household_id)))
     LEFT JOIN public.users req ON ((c.requested_by = req.user_id)))
     LEFT JOIN public.users app ON ((c.approved_by = app.user_id)));
 1   DROP VIEW public.view_household_changes_history;
       public       v       postgres    false    219    219    221    221    221    221    221    221    221    221    221    218    218    916    934    5            �            1259    18711    view_household_members    VIEW     \  CREATE VIEW public.view_household_members AS
 SELECT h.household_id,
    h.address,
    m.member_id,
    m.full_name,
    m.other_name,
    m.cccd,
    m.dob,
    m.gender,
    m.relationship,
    m.is_temporary,
    m.note,
    m.joined_at
   FROM (public.households h
     JOIN public.household_members m ON ((h.household_id = m.household_id)));
 )   DROP VIEW public.view_household_members;
       public       v       postgres    false    220    220    220    220    220    219    219    220    220    220    220    220    220    931    5            �            1259    18751 !   view_household_population_summary    VIEW     �  CREATE VIEW public.view_household_population_summary AS
 SELECT h.household_id,
    h.address,
    count(m.member_id) AS num_members,
    sum(
        CASE
            WHEN m.is_temporary THEN 1
            ELSE 0
        END) AS num_temporary_members
   FROM (public.households h
     LEFT JOIN public.household_members m ON ((h.household_id = m.household_id)))
  GROUP BY h.household_id, h.address;
 4   DROP VIEW public.view_household_population_summary;
       public       v       postgres    false    219    220    219    220    220    5            �            1259    18741    view_payment_history    VIEW     �  CREATE VIEW public.view_payment_history AS
 SELECT h.household_id,
    h.address,
    f.title AS fee_title,
    ph.amount,
    ph.transaction_id,
    ph.note,
    ph.created_at
   FROM (((public.payment_history ph
     JOIN public.households h ON ((ph.household_id = h.household_id)))
     JOIN public.payments p ON ((ph.payment_id = p.payment_id)))
     JOIN public.fees f ON ((p.fee_id = f.fee_id)));
 '   DROP VIEW public.view_payment_history;
       public       v       postgres    false    225    225    225    225    225    225    224    224    223    223    219    219    5            �            1259    18736    view_pending_fees_per_household    VIEW     �  CREATE VIEW public.view_pending_fees_per_household AS
 SELECT h.household_id,
    h.address,
    f.fee_id,
    f.title,
    f.amount,
    f.due_date
   FROM ((public.households h
     CROSS JOIN public.fees f)
     LEFT JOIN public.payments p ON (((f.fee_id = p.fee_id) AND (p.household_id = h.household_id))))
  WHERE ((p.status IS NULL) OR (p.status = 'unpaid'::public.payment_status));
 2   DROP VIEW public.view_pending_fees_per_household;
       public       v       postgres    false    219    223    223    925    223    224    224    224    219    223    5            �            1259    18721    view_pending_household_changes    VIEW     �  CREATE VIEW public.view_pending_household_changes AS
 SELECT c.change_id,
    h.address,
    c.change_type,
    c.description,
    u.fullname AS requested_by,
    c.created_at
   FROM ((public.household_changes c
     JOIN public.households h ON ((c.household_id = h.household_id)))
     LEFT JOIN public.users u ON ((c.requested_by = u.user_id)))
  WHERE (c.status = 'pending'::public.status_request);
 1   DROP VIEW public.view_pending_household_changes;
       public       v       postgres    false    221    221    221    221    916    218    218    219    219    221    221    221    934    5            �            1259    18716    view_pending_residency_requests    VIEW     p  CREATE VIEW public.view_pending_residency_requests AS
 SELECT r.request_id,
    u.fullname AS requester,
    r.request_type,
    r.from_date,
    r.to_date,
    r.destination,
    r.origin,
    r.reason,
    r.created_at
   FROM (public.residency_requests r
     JOIN public.users u ON ((r.user_id = u.user_id)))
  WHERE (r.status = 'pending'::public.status_request);
 2   DROP VIEW public.view_pending_residency_requests;
       public       v       postgres    false    218    916    218    222    222    222    222    222    222    222    222    222    222    5    919            �            1259    18731    view_residency_request_history    VIEW     L  CREATE VIEW public.view_residency_request_history AS
 SELECT r.request_id,
    u.fullname,
    r.request_type,
    r.from_date,
    r.to_date,
    r.destination,
    r.origin,
    r.reason,
    r.status,
    r.created_at,
    r.updated_at
   FROM (public.residency_requests r
     JOIN public.users u ON ((r.user_id = u.user_id)));
 1   DROP VIEW public.view_residency_request_history;
       public       v       postgres    false    222    222    222    222    218    218    222    222    222    222    222    222    222    919    916    5            0           2606    18663     approval_logs approval_logs_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.approval_logs
    ADD CONSTRAINT approval_logs_pkey PRIMARY KEY (log_id);
 J   ALTER TABLE ONLY public.approval_logs DROP CONSTRAINT approval_logs_pkey;
       public                 postgres    false    226            &           2606    18611    fees fees_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.fees
    ADD CONSTRAINT fees_pkey PRIMARY KEY (fee_id);
 8   ALTER TABLE ONLY public.fees DROP CONSTRAINT fees_pkey;
       public                 postgres    false    223                       2606    18570 (   household_changes household_changes_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.household_changes
    ADD CONSTRAINT household_changes_pkey PRIMARY KEY (change_id);
 R   ALTER TABLE ONLY public.household_changes DROP CONSTRAINT household_changes_pkey;
       public                 postgres    false    221                       2606    18554 ,   household_members household_members_cccd_key 
   CONSTRAINT     g   ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT household_members_cccd_key UNIQUE (cccd);
 V   ALTER TABLE ONLY public.household_members DROP CONSTRAINT household_members_cccd_key;
       public                 postgres    false    220                       2606    18552 (   household_members household_members_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT household_members_pkey PRIMARY KEY (member_id);
 R   ALTER TABLE ONLY public.household_members DROP CONSTRAINT household_members_pkey;
       public                 postgres    false    220                       2606    18536 *   households households_household_number_key 
   CONSTRAINT     q   ALTER TABLE ONLY public.households
    ADD CONSTRAINT households_household_number_key UNIQUE (household_number);
 T   ALTER TABLE ONLY public.households DROP CONSTRAINT households_household_number_key;
       public                 postgres    false    219                       2606    18534    households households_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.households
    ADD CONSTRAINT households_pkey PRIMARY KEY (household_id);
 D   ALTER TABLE ONLY public.households DROP CONSTRAINT households_pkey;
       public                 postgres    false    219            5           2606    18692    instructions instructions_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.instructions
    ADD CONSTRAINT instructions_pkey PRIMARY KEY (instruction_id);
 H   ALTER TABLE ONLY public.instructions DROP CONSTRAINT instructions_pkey;
       public                 postgres    false    228            3           2606    18679     notifications notifications_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);
 J   ALTER TABLE ONLY public.notifications DROP CONSTRAINT notifications_pkey;
       public                 postgres    false    227            .           2606    18643 $   payment_history payment_history_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.payment_history
    ADD CONSTRAINT payment_history_pkey PRIMARY KEY (history_id);
 N   ALTER TABLE ONLY public.payment_history DROP CONSTRAINT payment_history_pkey;
       public                 postgres    false    225            ,           2606    18624    payments payments_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);
 @   ALTER TABLE ONLY public.payments DROP CONSTRAINT payments_pkey;
       public                 postgres    false    224            $           2606    18597 *   residency_requests residency_requests_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.residency_requests
    ADD CONSTRAINT residency_requests_pkey PRIMARY KEY (request_id);
 T   ALTER TABLE ONLY public.residency_requests DROP CONSTRAINT residency_requests_pkey;
       public                 postgres    false    222                       2606    18521    users users_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public                 postgres    false    218                       2606    18523    users users_username_key 
   CONSTRAINT     W   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);
 B   ALTER TABLE ONLY public.users DROP CONSTRAINT users_username_key;
       public                 postgres    false    218            '           1259    18708    idx_fees_due_date    INDEX     F   CREATE INDEX idx_fees_due_date ON public.fees USING btree (due_date);
 %   DROP INDEX public.idx_fees_due_date;
       public                 postgres    false    223                        1259    18707 !   idx_household_changes_status_type    INDEX     n   CREATE INDEX idx_household_changes_status_type ON public.household_changes USING btree (status, change_type);
 5   DROP INDEX public.idx_household_changes_status_type;
       public                 postgres    false    221    221                       1259    18702 "   idx_household_members_household_id    INDEX     h   CREATE INDEX idx_household_members_household_id ON public.household_members USING btree (household_id);
 6   DROP INDEX public.idx_household_members_household_id;
       public                 postgres    false    220            1           1259    18710    idx_notifications_user_id_read    INDEX     d   CREATE INDEX idx_notifications_user_id_read ON public.notifications USING btree (user_id, is_read);
 2   DROP INDEX public.idx_notifications_user_id_read;
       public                 postgres    false    227    227            (           1259    18704    idx_payments_fee_id    INDEX     J   CREATE INDEX idx_payments_fee_id ON public.payments USING btree (fee_id);
 '   DROP INDEX public.idx_payments_fee_id;
       public                 postgres    false    224            )           1259    18703    idx_payments_household_id    INDEX     V   CREATE INDEX idx_payments_household_id ON public.payments USING btree (household_id);
 -   DROP INDEX public.idx_payments_household_id;
       public                 postgres    false    224            *           1259    18709    idx_payments_status_method    INDEX     Y   CREATE INDEX idx_payments_status_method ON public.payments USING btree (status, method);
 .   DROP INDEX public.idx_payments_status_method;
       public                 postgres    false    224    224            !           1259    18706    idx_residency_requests_status    INDEX     ^   CREATE INDEX idx_residency_requests_status ON public.residency_requests USING btree (status);
 1   DROP INDEX public.idx_residency_requests_status;
       public                 postgres    false    222            "           1259    18705    idx_residency_requests_user_id    INDEX     `   CREATE INDEX idx_residency_requests_user_id ON public.residency_requests USING btree (user_id);
 2   DROP INDEX public.idx_residency_requests_user_id;
       public                 postgres    false    222            �           2618    18749 #   view_fee_collection_summary _RETURN    RULE     �  CREATE OR REPLACE VIEW public.view_fee_collection_summary AS
 SELECT f.fee_id,
    f.title,
    f.amount AS amount_per_household,
    count(p.payment_id) AS num_households_paid,
    sum(ph.amount) AS total_collected,
    f.due_date
   FROM ((public.fees f
     LEFT JOIN public.payments p ON (((f.fee_id = p.fee_id) AND (p.status = 'paid'::public.payment_status))))
     LEFT JOIN public.payment_history ph ON ((p.payment_id = ph.payment_id)))
  GROUP BY f.fee_id;
   CREATE OR REPLACE VIEW public.view_fee_collection_summary AS
SELECT
    NULL::uuid AS fee_id,
    NULL::text AS title,
    NULL::numeric(12,2) AS amount_per_household,
    NULL::bigint AS num_households_paid,
    NULL::numeric AS total_collected,
    NULL::date AS due_date;
       public               postgres    false    223    223    223    223    4902    224    925    224    224    225    225    236            I           2620    18757    fees trigger_fee_notifications    TRIGGER     �   CREATE TRIGGER trigger_fee_notifications AFTER INSERT ON public.fees FOR EACH ROW EXECUTE FUNCTION public.create_fee_notifications();
 7   DROP TRIGGER trigger_fee_notifications ON public.fees;
       public               postgres    false    223    277            C           2620    18694    users trigger_hash    TRIGGER     q   CREATE TRIGGER trigger_hash BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.hash();
 +   DROP TRIGGER trigger_hash ON public.users;
       public               postgres    false    274    218            J           2620    18701 $   payments trigger_log_payment_history    TRIGGER     �   CREATE TRIGGER trigger_log_payment_history AFTER INSERT ON public.payments FOR EACH ROW EXECUTE FUNCTION public.log_payment_history();
 =   DROP TRIGGER trigger_log_payment_history ON public.payments;
       public               postgres    false    276    224            G           2620    18699 2   household_changes trigger_update_household_changes    TRIGGER     �   CREATE TRIGGER trigger_update_household_changes BEFORE UPDATE ON public.household_changes FOR EACH ROW EXECUTE FUNCTION public.updated();
 K   DROP TRIGGER trigger_update_household_changes ON public.household_changes;
       public               postgres    false    221    275            F           2620    18759 /   household_members trigger_update_household_size    TRIGGER     �   CREATE TRIGGER trigger_update_household_size AFTER INSERT OR DELETE OR UPDATE ON public.household_members FOR EACH ROW EXECUTE FUNCTION public.update_household_size();
 H   DROP TRIGGER trigger_update_household_size ON public.household_members;
       public               postgres    false    289    220            E           2620    18697 $   households trigger_update_households    TRIGGER     |   CREATE TRIGGER trigger_update_households BEFORE UPDATE ON public.households FOR EACH ROW EXECUTE FUNCTION public.updated();
 =   DROP TRIGGER trigger_update_households ON public.households;
       public               postgres    false    219    275            H           2620    18698 4   residency_requests trigger_update_residency_requests    TRIGGER     �   CREATE TRIGGER trigger_update_residency_requests BEFORE UPDATE ON public.residency_requests FOR EACH ROW EXECUTE FUNCTION public.updated();
 M   DROP TRIGGER trigger_update_residency_requests ON public.residency_requests;
       public               postgres    false    275    222            D           2620    18696    users trigger_update_user    TRIGGER     q   CREATE TRIGGER trigger_update_user BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.updated();
 2   DROP TRIGGER trigger_update_user ON public.users;
       public               postgres    false    275    218            A           2606    18664 ,   approval_logs approval_logs_approved_by_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.approval_logs
    ADD CONSTRAINT approval_logs_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(user_id);
 V   ALTER TABLE ONLY public.approval_logs DROP CONSTRAINT approval_logs_approved_by_fkey;
       public               postgres    false    218    226    4882            <           2606    18612    fees fees_created_by_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.fees
    ADD CONSTRAINT fees_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);
 C   ALTER TABLE ONLY public.fees DROP CONSTRAINT fees_created_by_fkey;
       public               postgres    false    223    4882    218            8           2606    18581 4   household_changes household_changes_approved_by_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.household_changes
    ADD CONSTRAINT household_changes_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(user_id);
 ^   ALTER TABLE ONLY public.household_changes DROP CONSTRAINT household_changes_approved_by_fkey;
       public               postgres    false    221    4882    218            9           2606    18571 5   household_changes household_changes_household_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.household_changes
    ADD CONSTRAINT household_changes_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households(household_id);
 _   ALTER TABLE ONLY public.household_changes DROP CONSTRAINT household_changes_household_id_fkey;
       public               postgres    false    219    221    4888            :           2606    18576 5   household_changes household_changes_requested_by_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.household_changes
    ADD CONSTRAINT household_changes_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES public.users(user_id);
 _   ALTER TABLE ONLY public.household_changes DROP CONSTRAINT household_changes_requested_by_fkey;
       public               postgres    false    218    4882    221            7           2606    18555 5   household_members household_members_household_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.household_members
    ADD CONSTRAINT household_members_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households(household_id) ON UPDATE CASCADE ON DELETE CASCADE;
 _   ALTER TABLE ONLY public.household_members DROP CONSTRAINT household_members_household_id_fkey;
       public               postgres    false    220    219    4888            6           2606    18537 "   households households_head_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.households
    ADD CONSTRAINT households_head_id_fkey FOREIGN KEY (head_id) REFERENCES public.users(user_id);
 L   ALTER TABLE ONLY public.households DROP CONSTRAINT households_head_id_fkey;
       public               postgres    false    218    4882    219            B           2606    18680 (   notifications notifications_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 R   ALTER TABLE ONLY public.notifications DROP CONSTRAINT notifications_user_id_fkey;
       public               postgres    false    227    218    4882            ?           2606    18649 1   payment_history payment_history_household_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.payment_history
    ADD CONSTRAINT payment_history_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households(household_id) ON DELETE CASCADE;
 [   ALTER TABLE ONLY public.payment_history DROP CONSTRAINT payment_history_household_id_fkey;
       public               postgres    false    4888    219    225            @           2606    18644 /   payment_history payment_history_payment_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.payment_history
    ADD CONSTRAINT payment_history_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES public.payments(payment_id) ON DELETE CASCADE;
 Y   ALTER TABLE ONLY public.payment_history DROP CONSTRAINT payment_history_payment_id_fkey;
       public               postgres    false    225    224    4908            =           2606    18625    payments payments_fee_id_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_fee_id_fkey FOREIGN KEY (fee_id) REFERENCES public.fees(fee_id);
 G   ALTER TABLE ONLY public.payments DROP CONSTRAINT payments_fee_id_fkey;
       public               postgres    false    4902    224    223            >           2606    18630 #   payments payments_household_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_household_id_fkey FOREIGN KEY (household_id) REFERENCES public.households(household_id);
 M   ALTER TABLE ONLY public.payments DROP CONSTRAINT payments_household_id_fkey;
       public               postgres    false    224    4888    219            ;           2606    18598 2   residency_requests residency_requests_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.residency_requests
    ADD CONSTRAINT residency_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE CASCADE;
 \   ALTER TABLE ONLY public.residency_requests DROP CONSTRAINT residency_requests_user_id_fkey;
       public               postgres    false    4882    222    218           