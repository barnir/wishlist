import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';

/// Comprehensive validation utilities for form inputs and security
class ValidationUtils {
  // Email validation
  static String? validateEmail(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return l10n?.emailRequired ?? 'Email é obrigatório';
    }
    
    final email = value.trim().toLowerCase();
    
    // Basic format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email)) {
      return l10n?.emailInvalid ?? 'Email inválido';
    }
    
    // Length validation
    if (email.length > 254) {
      return l10n?.emailTooLong ?? 'Email demasiado longo';
    }
    
    // Domain validation
    final parts = email.split('@');
    if (parts[1].length > 253) {
      return l10n?.emailDomainInvalid ?? 'Domínio do email inválido';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.isEmpty) {
      return l10n?.passwordRequired ?? 'Password é obrigatória';
    }
    
    if (value.length < 8) {
      return l10n?.passwordTooShort ?? 'Password deve ter pelo menos 8 caracteres';
    }
    
    if (value.length > 128) {
      return l10n?.passwordTooLong ?? 'Password demasiado longa';
    }
    
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return l10n?.passwordNeedUpper ?? 'Password deve conter pelo menos uma letra maiúscula';
    }
    
    // Check for at least one lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return l10n?.passwordNeedLower ?? 'Password deve conter pelo menos uma letra minúscula';
    }
    
    // Check for at least one digit
    if (!value.contains(RegExp(r'[0-9]'))) {
      return l10n?.passwordNeedNumber ?? 'Password deve conter pelo menos um número';
    }
    
    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return l10n?.passwordNeedSpecial ?? 'Password deve conter pelo menos um caracter especial';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return l10n?.nameRequired ?? 'Nome é obrigatório';
    }
    
    final name = value.trim();
    
    if (name.length < 2) {
      return l10n?.nameTooShort ?? 'Nome deve ter pelo menos 2 caracteres';
    }
    
    if (name.length > 50) {
      return l10n?.nameTooLong ?? 'Nome demasiado longo';
    }
    
    // Allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$");
    if (!nameRegex.hasMatch(name)) {
      return l10n?.nameInvalidChars ?? 'Nome contém caracteres inválidos';
    }
    
    return null;
  }

  // Phone number validation (Portuguese format)
  static String? validatePhoneNumber(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return l10n?.phoneRequired ?? 'Número de telefone é obrigatório';
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Portuguese mobile numbers: 9XXXXXXXX (9 digits starting with 9)
    if (digitsOnly.length == 9 && digitsOnly.startsWith('9')) {
      return null;
    }
    
    // International format: +351 9XXXXXXXX
    if (digitsOnly.length == 12 && digitsOnly.startsWith('3519')) {
      return null;
    }
    
  return l10n?.phoneInvalidFormat ?? 'Número de telefone inválido (formato: 9XXXXXXXX)';
  }

  // URL validation and sanitization
  static String? validateAndSanitizeUrl(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional in most cases
    }
    
    String url = value.trim();
    
    // Add protocol if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    try {
      final uri = Uri.parse(url);
      
      // Validate scheme
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return l10n?.urlMustBeHttp ?? 'URL deve usar HTTP ou HTTPS';
      }
      
      // Validate host
      if (uri.host.isEmpty) {
        return l10n?.urlInvalid ?? 'URL inválido';
      }
      
      // Check for localhost/private IPs (security)
      if (uri.host == 'localhost' || 
          uri.host.startsWith('127.') ||
          uri.host.startsWith('192.168.') ||
          uri.host.startsWith('10.') ||
          uri.host.startsWith('172.')) {
        return l10n?.urlLocalNotAllowed ?? 'URLs locais não são permitidos';
      }
      
      // Length validation
      if (url.length > 2048) {
        return l10n?.urlTooLong ?? 'URL demasiado longo';
      }
      
      return null;
    } catch (e) {
      return l10n?.urlInvalid ?? 'URL inválido';
    }
  }

  // Pure helper to sanitize (NOT validate) a URL for saving; keeps logic consistent with validator.
  static String sanitizeUrlForSave(String? value) {
    if (value == null) return '';
    var url = value.trim();
    if (url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  // Sanitize URL for safe use
  static String sanitizeUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  // Price validation
  static String? validatePrice(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return null; // Price is optional
    }
    
    // Remove currency symbols and whitespace
    final cleanValue = value.replaceAll(RegExp(r'[€$£\s]'), '').trim();
    
    if (cleanValue.isEmpty) {
      return null;
    }
    
    // Parse as double
    final price = double.tryParse(cleanValue.replaceAll(',', '.'));
    
    if (price == null) {
      return l10n?.priceInvalid ?? 'Preço inválido';
    }
    
    if (price < 0) {
      return l10n?.priceNegative ?? 'Preço não pode ser negativo';
    }
    
    if (price > 999999.99) {
      return l10n?.priceTooHigh ?? 'Preço demasiado alto';
    }
    
    return null;
  }

  // Description validation
  static String? validateDescription(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return null; // Description is optional
    }
    
    final description = value.trim();
    
    if (description.length > 500) {
      return l10n?.descriptionTooLong ?? 'Descrição demasiado longa (máximo 500 caracteres)';
    }
    
    return null;
  }

  // Wishlist name validation
  static String? validateWishlistName(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return l10n?.wishlistNameRequired ?? 'Nome da wishlist é obrigatório';
    }
    
    final name = value.trim();
    
    if (name.length < 2) {
      return l10n?.wishlistNameTooShort ?? 'Nome deve ter pelo menos 2 caracteres';
    }
    
    if (name.length > 100) {
      return l10n?.wishlistNameTooLong ?? 'Nome demasiado longo';
    }
    
    return null;
  }

  // Item name validation
  static String? validateItemName(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return l10n?.itemNameRequired ?? 'Nome do item é obrigatório';
    }
    
    final name = value.trim();
    
    if (name.length < 2) {
      return l10n?.itemNameTooShort ?? 'Nome deve ter pelo menos 2 caracteres';
    }
    
    if (name.length > 100) {
      return l10n?.itemNameTooLong ?? 'Nome demasiado longo';
    }
    
    return null;
  }

  // Image file validation
  static String? validateImageFile(File? file, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (file == null) {
      return null; // Image is optional
    }
    
    // Check file size (max 10MB)
    final sizeInBytes = file.lengthSync();
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    
    if (sizeInBytes > maxSizeInBytes) {
      return l10n?.imageTooLarge ?? 'Imagem demasiado grande (máximo 10MB)';
    }
    
    // Check file extension - Android optimized formats
    final extension = file.path.toLowerCase().split('.').last;
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    
    if (!allowedExtensions.contains(extension)) {
      return l10n?.imageFormatUnsupported ?? 'Formato de imagem não suportado (use JPG, PNG ou GIF)';
    }
    
    return null;
  }

  // Generic text input sanitization
  static String sanitizeTextInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp('[<>"\'&]'), '') // Remove potentially dangerous characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  // Check if string contains potentially harmful content
  static bool containsSuspiciousContent(String input) {
    final suspicious = [
      '<script',
      'javascript:',
      'data:',
      'vbscript:',
      'onload=',
      'onerror=',
      'onclick=',
    ];
    
    final lowerInput = input.toLowerCase();
    return suspicious.any((pattern) => lowerInput.contains(pattern));
  }

  // Validate OTP code
  static String? validateOtpCode(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return l10n?.otpCodeRequired ?? 'Código é obrigatório';
    }
    
    final code = value.trim().replaceAll(RegExp(r'\s'), '');
    
    if (code.length != 6) {
      return l10n?.otpCodeLength ?? 'Código deve ter 6 dígitos';
    }
    
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return l10n?.otpCodeDigitsOnly ?? 'Código deve conter apenas números';
    }
    
  return null;
  }

  // Convenience generators for FormField validators using context to localize messages
  static FormFieldValidator<String> emailValidator(BuildContext context) =>
    (value) => validateEmail(value, context);
  static FormFieldValidator<String> passwordValidator(BuildContext context) =>
    (value) => validatePassword(value, context);
  static FormFieldValidator<String> nameValidator(BuildContext context) =>
    (value) => validateName(value, context);
  static FormFieldValidator<String> phoneValidator(BuildContext context) =>
    (value) => validatePhoneNumber(value, context);
  static FormFieldValidator<String> urlValidator(BuildContext context) =>
    (value) => validateAndSanitizeUrl(value, context);
  static FormFieldValidator<String> priceValidator(BuildContext context) =>
    (value) => validatePrice(value, context);
  static FormFieldValidator<String> descriptionValidator(BuildContext context) =>
    (value) => validateDescription(value, context);
  static FormFieldValidator<String> wishlistNameValidator(BuildContext context) =>
    (value) => validateWishlistName(value, context);
  static FormFieldValidator<String> itemNameValidator(BuildContext context) =>
    (value) => validateItemName(value, context);
  static FormFieldValidator<String> otpCodeValidator(BuildContext context) =>
    (value) => validateOtpCode(value, context);

  // Additional domain-specific validators
  static String? validateQuantity(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.trim().isEmpty) {
      return l10n?.quantityRequired ?? 'Insere a quantidade';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < 1) {
      return l10n?.quantityInvalid ?? 'Quantidade inválida';
    }
    return null;
  }

  static String? validateWishlistSelection(String? value, [BuildContext? context]) {
    final l10n = context != null ? AppLocalizations.of(context) : null;
    if (value == null || value.isEmpty) {
      return l10n?.chooseWishlistValidation ?? 'Por favor, escolha uma wishlist';
    }
    return null;
  }

  static FormFieldValidator<String> quantityValidator(BuildContext context) =>
      (value) => validateQuantity(value, context);
  static FormFieldValidator<String> wishlistSelectionValidator(BuildContext context) =>
      (value) => validateWishlistSelection(value, context);
}