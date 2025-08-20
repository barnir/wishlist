-- Script para corrigir problemas específicos no schema atual
-- Execute este script no SQL Editor do Supabase

-- PROBLEMA 1: Constraint UNIQUE no email pode causar problemas para usuários sem email
-- Solução: Remover a constraint UNIQUE e criar uma constraint condicional

-- 1. Remover a constraint UNIQUE do email
ALTER TABLE public.users 
DROP CONSTRAINT IF EXISTS users_email_key;

-- 2. Adicionar constraint UNIQUE condicional (apenas para emails não nulos)
ALTER TABLE public.users 
ADD CONSTRAINT users_email_unique_when_not_null 
UNIQUE NULLS NOT DISTINCT (email);

-- PROBLEMA 2: Constraints duplicadas na tabela friends
-- Solução: Remover constraints duplicadas

-- 3. Remover constraints duplicadas da tabela friends
ALTER TABLE public.friends 
DROP CONSTRAINT IF EXISTS fk_friend;

ALTER TABLE public.friends 
DROP CONSTRAINT IF EXISTS fk_user;

-- Manter apenas as constraints corretas:
-- - friends_user_id_fkey (referencia public.users)
-- - friends_friend_id_fkey (referencia public.users)

-- PROBLEMA 3: Constraints duplicadas na tabela wishlists
-- Solução: Remover constraints duplicadas

-- 4. Remover constraints duplicadas da tabela wishlists
ALTER TABLE public.wishlists 
DROP CONSTRAINT IF EXISTS fk_owner;

-- Manter apenas a constraint correta:
-- - wishlists_owner_id_fkey (referencia public.users)

-- PROBLEMA 4: Constraints duplicadas na tabela wish_items
-- Solução: Remover constraints duplicadas

-- 5. Remover constraints duplicadas da tabela wish_items
ALTER TABLE public.wish_items 
DROP CONSTRAINT IF EXISTS fk_wishlist;

-- Manter apenas a constraint correta:
-- - wish_items_wishlist_id_fkey (referencia public.wishlists)

-- PROBLEMA 5: Adicionar RLS (Row Level Security) para proteger os dados

-- 6. Habilitar RLS nas tabelas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_items ENABLE ROW LEVEL SECURITY;

-- 7. Criar políticas RLS para a tabela users
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 8. Criar políticas RLS para a tabela friends
CREATE POLICY "Users can view their friends" ON public.friends
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can add friends" ON public.friends
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their friends" ON public.friends
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Criar políticas RLS para a tabela wishlists
CREATE POLICY "Users can view their own wishlists" ON public.wishlists
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can view public wishlists" ON public.wishlists
    FOR SELECT USING (is_private = false);

CREATE POLICY "Users can create wishlists" ON public.wishlists
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own wishlists" ON public.wishlists
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own wishlists" ON public.wishlists
    FOR DELETE USING (auth.uid() = owner_id);

-- 10. Criar políticas RLS para a tabela wish_items
CREATE POLICY "Users can view items in their wishlists" ON public.wish_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.wishlists 
            WHERE id = wish_items.wishlist_id 
            AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can view items in public wishlists" ON public.wish_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.wishlists 
            WHERE id = wish_items.wishlist_id 
            AND is_private = false
        )
    );

CREATE POLICY "Users can create items in their wishlists" ON public.wish_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.wishlists 
            WHERE id = wish_items.wishlist_id 
            AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can update items in their wishlists" ON public.wish_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.wishlists 
            WHERE id = wish_items.wishlist_id 
            AND owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete items in their wishlists" ON public.wish_items
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.wishlists 
            WHERE id = wish_items.wishlist_id 
            AND owner_id = auth.uid()
        )
    );

-- 11. Criar função para verificar se um usuário tem telefone
CREATE OR REPLACE FUNCTION user_has_phone(user_uuid uuid)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = user_uuid 
        AND phone_number IS NOT NULL 
        AND phone_number != ''
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Criar função para verificar se um usuário tem email
CREATE OR REPLACE FUNCTION user_has_email(user_uuid uuid)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = user_uuid 
        AND email IS NOT NULL 
        AND email != ''
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Criar trigger para validar dados antes de inserir/atualizar
CREATE OR REPLACE FUNCTION validate_user_data_trigger()
RETURNS trigger AS $$
BEGIN
    -- Garantir que pelo menos telefone OU email exista
    IF (NEW.email IS NULL OR NEW.email = '') AND (NEW.phone_number IS NULL OR NEW.phone_number = '') THEN
        RAISE EXCEPTION 'Usuário deve ter pelo menos email ou telefone';
    END IF;
    
    -- Garantir que telefone seja sempre obrigatório (nossa regra principal)
    IF NEW.phone_number IS NULL OR NEW.phone_number = '' THEN
        RAISE EXCEPTION 'Número de telefone é obrigatório para todos os usuários';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 14. Aplicar o trigger na tabela users
DROP TRIGGER IF EXISTS validate_user_data_trigger ON public.users;
CREATE TRIGGER validate_user_data_trigger
    BEFORE INSERT OR UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION validate_user_data_trigger();

-- 15. Verificar se as correções foram aplicadas
SELECT 
    'Schema corrections applied successfully' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN phone_number IS NOT NULL AND phone_number != '' THEN 1 END) as users_with_phone,
    COUNT(CASE WHEN email IS NOT NULL AND email != '' THEN 1 END) as users_with_email
FROM public.users;
