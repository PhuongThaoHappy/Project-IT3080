PGDMP      ,                }            Complex    17.4    17.4     �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    17618    Complex    DATABASE     o   CREATE DATABASE "Complex" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en-US';
    DROP DATABASE "Complex";
                     postgres    false            �          0    18511    users 
   TABLE DATA           q   COPY public.users (user_id, username, password_hash, role, fullname, status, created_at, updated_at) FROM stdin;
    public               postgres    false    218   Y       �          0    18654    approval_logs 
   TABLE DATA           m   COPY public.approval_logs (log_id, request_id, change_id, approved_by, action, note, created_at) FROM stdin;
    public               postgres    false    226   v       �          0    18603    fees 
   TABLE DATA           j   COPY public.fees (fee_id, title, description, type, amount, due_date, created_by, created_at) FROM stdin;
    public               postgres    false    223   �       �          0    18524 
   households 
   TABLE DATA           ~   COPY public.households (household_id, household_number, head_id, household_size, address, created_at, updated_at) FROM stdin;
    public               postgres    false    219   �       �          0    18560    household_changes 
   TABLE DATA           �   COPY public.household_changes (change_id, household_id, change_type, description, requested_by, approved_by, status, created_at, updated_at) FROM stdin;
    public               postgres    false    221   �       �          0    18542    household_members 
   TABLE DATA           �   COPY public.household_members (member_id, household_id, full_name, gender, other_name, dob, place_of_birth, native_place, ethnic_group, occupation, place_of_work, cccd, issue_date, issued_by, relationship, is_temporary, note, joined_at) FROM stdin;
    public               postgres    false    220   �       �          0    18685    instructions 
   TABLE DATA           P   COPY public.instructions (instruction_id, title, content, for_role) FROM stdin;
    public               postgres    false    228          �          0    18669    notifications 
   TABLE DATA           �   COPY public.notifications (notification_id, user_id, title, content, notification_type, is_read, push_sent, push_sent_at, created_at) FROM stdin;
    public               postgres    false    227   $       �          0    18617    payments 
   TABLE DATA           ]   COPY public.payments (payment_id, fee_id, household_id, paid_at, method, status) FROM stdin;
    public               postgres    false    224   A       �          0    18635    payment_history 
   TABLE DATA           y   COPY public.payment_history (history_id, payment_id, household_id, amount, transaction_id, note, created_at) FROM stdin;
    public               postgres    false    225   ^       �          0    18586    residency_requests 
   TABLE DATA           �   COPY public.residency_requests (request_id, user_id, request_type, from_date, to_date, destination, origin, reason, status, created_at, updated_at) FROM stdin;
    public               postgres    false    222   {       �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �     