# OnePay iOS Application
# Typography Specification
### Developer Reference Guide

**Version 1.0 | January 2026**

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Research Findings](#2-research-findings)
3. [Recommended Typography System](#3-recommended-typography-system)
4. [Detailed Typography Specifications](#4-detailed-typography-specifications)
5. [Font Weight Reference](#5-font-weight-reference)
6. [Line Height & Spacing](#6-line-height--spacing)
7. [React Native Implementation](#7-react-native-implementation)
8. [Accessibility Requirements](#8-accessibility-requirements)
9. [Typography Color Palette](#9-typography-color-palette)
10. [Best Practices & Guidelines](#10-best-practices--guidelines)
11. [Appendix](#11-appendix)

---

## 1. Executive Summary

This document provides comprehensive typography specifications for the OnePay iOS mobile banking application developed by One Finance, Inc. The specifications are based on extensive research of the application, iOS Human Interface Guidelines, React Native best practices, and fintech industry standards.

> ⚠️ **Important:** OnePay has not publicly released official brand guidelines or design system documentation. The specifications in this document are derived from analysis of publicly available screenshots, app store listings, and industry-standard practices for similar fintech applications.

---

## 2. Research Findings

### 2.1 Application Overview

| Property | Value |
|----------|-------|
| **App Name** | OnePay – Mobile Banking |
| **Developer** | One Finance, Inc. |
| **Platform** | iOS (React Native) |
| **Minimum iOS Version** | iOS 15.1+ |
| **Current App Version** | 5.45.0 (as of December 2025) |
| **App Category** | Finance / Mobile Banking |
| **Design Approach** | Minimalist, Clean, Modern |

### 2.2 Key Research Findings

- OnePay does not publish public design system documentation or brand guidelines
- The app uses React Native framework for cross-platform development
- UI design work was performed by Qubika (third-party design agency)
- The application follows iOS Human Interface Guidelines for typography
- Fintech industry standard: Sans-serif fonts dominate for trust and readability
- No official font family names were found in public documentation

---

## 3. Recommended Typography System

Based on iOS standards, React Native capabilities, and fintech best practices, the following typography system is recommended for OnePay iOS implementation.

### 3.1 Primary Font Family: SF Pro (San Francisco)

SF Pro is Apple's system font, designed specifically for iOS interfaces. It provides excellent legibility, supports Dynamic Type, and is automatically available on all iOS devices without bundling.

| Property | Value |
|----------|-------|
| **Font Family** | SF Pro (San Francisco) |
| **Display Variant** | SF Pro Display (for sizes 20pt and above) |
| **Text Variant** | SF Pro Text (for sizes below 20pt) |
| **Rounded Variant** | SF Pro Rounded (optional for friendly UI elements) |
| **Monospace Variant** | SF Mono (for account numbers, codes) |
| **License** | Free for iOS/macOS development |

### 3.2 Alternative Font Options

If custom fonts are required for brand differentiation, consider these alternatives commonly used in fintech applications:

| Font Name | Type | Best For |
|-----------|------|----------|
| **Inter** | Free / Open Source | UI interfaces, very similar to SF Pro, Google Fonts |
| **Roboto** | Free / Google | Cross-platform consistency, Material Design |
| **Proxima Nova** | Commercial | Premium fintech apps, modern geometric style |
| **Helvetica Neue** | System Font | Classic, professional, available on iOS |
| **Avenir Next** | System Font | Geometric, friendly, good for fintech |
| **Poppins** | Free / Google | Geometric, modern, good weight range |

---

## 4. Detailed Typography Specifications

### 4.1 Headings & Titles

| Element | Font | Size | Weight | Usage |
|---------|------|------|--------|-------|
| **Large Title** | SF Pro Display | 34pt | Bold (700) | Main screen titles |
| **Title 1** | SF Pro Display | 28pt | Bold (700) | Section headers |
| **Title 2** | SF Pro Display | 22pt | Bold (700) | Card titles, modal headers |
| **Title 3** | SF Pro Display | 20pt | Semibold (600) | Sub-section titles |
| **Headline** | SF Pro Text | 17pt | Semibold (600) | List item titles |

### 4.2 Body Text & Content

| Element | Font | Size | Weight | Usage |
|---------|------|------|--------|-------|
| **Body** | SF Pro Text | 17pt | Regular (400) | Primary body text |
| **Callout** | SF Pro Text | 16pt | Regular (400) | Secondary descriptions |
| **Subhead** | SF Pro Text | 15pt | Regular (400) | Supporting text |
| **Footnote** | SF Pro Text | 13pt | Regular (400) | Disclaimers, fine print |
| **Caption 1** | SF Pro Text | 12pt | Regular (400) | Labels, timestamps |
| **Caption 2** | SF Pro Text | 11pt | Regular (400) | Minimum readable (use sparingly) |

### 4.3 Financial Data & Numbers

| Element | Font | Size | Weight | Usage |
|---------|------|------|--------|-------|
| **Account Balance (Large)** | SF Pro Display | 48pt | Bold (700) | Main balance display |
| **Account Balance (Medium)** | SF Pro Display | 34pt | Semibold (600) | Card balances |
| **Transaction Amount** | SF Pro Text | 17pt | Medium (500) | Transaction list items |
| **Account Number** | SF Mono | 15pt | Regular (400) | Account/routing numbers |
| **Verification Code** | SF Mono | 24pt | Medium (500) | OTP, PIN entry |
| **APY / Interest Rate** | SF Pro Display | 28pt | Bold (700) | Promotional rates |
| **Percentage Badge** | SF Pro Text | 13pt | Semibold (600) | Cashback, rewards % |

> 📌 **Note:** Use tabular (monospaced) figures for financial amounts to ensure proper alignment in lists and tables. SF Pro supports this via font features.

### 4.4 UI Components

| Element | Font | Size | Weight | Notes |
|---------|------|------|--------|-------|
| **Primary Button** | SF Pro Text | 17pt | Semibold (600) | All caps optional |
| **Secondary Button** | SF Pro Text | 17pt | Medium (500) | Sentence case |
| **Text Button / Link** | SF Pro Text | 17pt | Regular (400) | Primary color |
| **Tab Bar Label** | SF Pro Text | 10pt | Medium (500) | Below icons |
| **Navigation Title** | SF Pro Text | 17pt | Semibold (600) | Nav bar center |
| **Text Field Label** | SF Pro Text | 13pt | Regular (400) | Above input fields |
| **Text Field Input** | SF Pro Text | 17pt | Regular (400) | User-entered text |
| **Placeholder Text** | SF Pro Text | 17pt | Regular (400) | Gray color (#9CA3AF) |
| **Error Message** | SF Pro Text | 13pt | Regular (400) | Red color (#EF4444) |
| **Badge / Chip** | SF Pro Text | 12pt | Medium (500) | Status indicators |
| **Tooltip** | SF Pro Text | 13pt | Regular (400) | Help text overlays |

### 4.5 Contact & Personal Information

| Element | Font | Size | Weight | Usage |
|---------|------|------|--------|-------|
| **Contact Name (Primary)** | SF Pro Text | 17pt | Semibold (600) | Send money recipient |
| **Contact Name (List)** | SF Pro Text | 17pt | Regular (400) | Contact list items |
| **User Name (Header)** | SF Pro Display | 22pt | Semibold (600) | Profile header |
| **Phone Number** | SF Pro Text | 15pt | Regular (400) | Contact details |
| **Email Address** | SF Pro Text | 15pt | Regular (400) | Contact details |
| **Address** | SF Pro Text | 15pt | Regular (400) | Multi-line address |

---

## 5. Font Weight Reference

SF Pro provides 9 weights. Use these consistently throughout the application:

| Weight Name | Numeric Value | Usage Guidelines |
|-------------|---------------|------------------|
| **Ultralight** | 100 | Decorative only, avoid for body text |
| **Thin** | 200 | Large display text, promotional |
| **Light** | 300 | Large text, subtle emphasis |
| **Regular** | 400 | Default body text, descriptions |
| **Medium** | 500 | Slight emphasis, secondary buttons, amounts |
| **Semibold** | 600 | Headlines, navigation titles, buttons, contact names |
| **Bold** | 700 | Main titles, balances, strong emphasis |
| **Heavy** | 800 | Marketing headlines, rare use |
| **Black** | 900 | Extreme emphasis only, very limited use |

---

## 6. Line Height & Spacing

### 6.1 Line Height Multipliers

| Text Type | Line Height | Multiplier |
|-----------|-------------|------------|
| Large Title (34pt) | 41pt | 1.21x |
| Title 1 (28pt) | 34pt | 1.21x |
| Title 2 (22pt) | 28pt | 1.27x |
| Body (17pt) | 22pt | 1.29x |
| Callout (16pt) | 21pt | 1.31x |
| Subhead (15pt) | 20pt | 1.33x |
| Footnote (13pt) | 18pt | 1.38x |
| Caption (12pt) | 16pt | 1.33x |

### 6.2 Letter Spacing (Tracking)

| Text Type | Letter Spacing |
|-----------|----------------|
| Large Title | 0.374pt (tracking: 11) |
| Title 1 - Title 3 | 0.35pt (tracking: 10) |
| Body / Callout | -0.41pt (tracking: -12) |
| Caption / Footnote | 0pt (default) |
| All Caps Text | +0.5pt to +1.0pt (wider tracking) |

---

## 7. React Native Implementation

### 7.1 Using System Font (SF Pro)

React Native automatically uses SF Pro on iOS when specifying 'System' as the font family:

```javascript
// Uses SF Pro on iOS
fontFamily: 'System'

// Cross-platform
fontFamily: Platform.select({ 
  ios: 'System', 
  android: 'Roboto' 
})
```

### 7.2 Typography Style Constants

Create a centralized typography configuration file:

```typescript
// typography.ts

import { Platform, TextStyle } from 'react-native';

export const Typography: Record<string, TextStyle> = {
  
  // ============ HEADINGS ============
  
  largeTitle: {
    fontFamily: 'System',
    fontSize: 34,
    fontWeight: '700',
    lineHeight: 41,
    letterSpacing: 0.374,
  },
  
  title1: {
    fontFamily: 'System',
    fontSize: 28,
    fontWeight: '700',
    lineHeight: 34,
    letterSpacing: 0.35,
  },
  
  title2: {
    fontFamily: 'System',
    fontSize: 22,
    fontWeight: '700',
    lineHeight: 28,
    letterSpacing: 0.35,
  },
  
  title3: {
    fontFamily: 'System',
    fontSize: 20,
    fontWeight: '600',
    lineHeight: 25,
    letterSpacing: 0.35,
  },
  
  headline: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '600',
    lineHeight: 22,
    letterSpacing: -0.41,
  },
  
  // ============ BODY TEXT ============
  
  body: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '400',
    lineHeight: 22,
    letterSpacing: -0.41,
  },
  
  callout: {
    fontFamily: 'System',
    fontSize: 16,
    fontWeight: '400',
    lineHeight: 21,
    letterSpacing: -0.32,
  },
  
  subhead: {
    fontFamily: 'System',
    fontSize: 15,
    fontWeight: '400',
    lineHeight: 20,
    letterSpacing: -0.24,
  },
  
  footnote: {
    fontFamily: 'System',
    fontSize: 13,
    fontWeight: '400',
    lineHeight: 18,
    letterSpacing: -0.08,
  },
  
  caption1: {
    fontFamily: 'System',
    fontSize: 12,
    fontWeight: '400',
    lineHeight: 16,
    letterSpacing: 0,
  },
  
  caption2: {
    fontFamily: 'System',
    fontSize: 11,
    fontWeight: '400',
    lineHeight: 13,
    letterSpacing: 0.07,
  },
  
  // ============ FINANCIAL DATA ============
  
  balanceLarge: {
    fontFamily: 'System',
    fontSize: 48,
    fontWeight: '700',
    lineHeight: 52,
    fontVariant: ['tabular-nums'],
  },
  
  balanceMedium: {
    fontFamily: 'System',
    fontSize: 34,
    fontWeight: '600',
    lineHeight: 41,
    fontVariant: ['tabular-nums'],
  },
  
  transactionAmount: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '500',
    lineHeight: 22,
    fontVariant: ['tabular-nums'],
  },
  
  accountNumber: {
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    fontSize: 15,
    fontWeight: '400',
    lineHeight: 20,
    letterSpacing: 1,
  },
  
  verificationCode: {
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    fontSize: 24,
    fontWeight: '500',
    lineHeight: 32,
    letterSpacing: 4,
  },
  
  apyRate: {
    fontFamily: 'System',
    fontSize: 28,
    fontWeight: '700',
    lineHeight: 34,
  },
  
  percentageBadge: {
    fontFamily: 'System',
    fontSize: 13,
    fontWeight: '600',
    lineHeight: 18,
  },
  
  // ============ UI COMPONENTS ============
  
  buttonPrimary: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '600',
    lineHeight: 22,
    letterSpacing: -0.41,
  },
  
  buttonSecondary: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '500',
    lineHeight: 22,
    letterSpacing: -0.41,
  },
  
  buttonText: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '400',
    lineHeight: 22,
    letterSpacing: -0.41,
  },
  
  tabBarLabel: {
    fontFamily: 'System',
    fontSize: 10,
    fontWeight: '500',
    lineHeight: 12,
  },
  
  navigationTitle: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '600',
    lineHeight: 22,
  },
  
  textFieldLabel: {
    fontFamily: 'System',
    fontSize: 13,
    fontWeight: '400',
    lineHeight: 18,
  },
  
  textFieldInput: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '400',
    lineHeight: 22,
  },
  
  placeholder: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '400',
    lineHeight: 22,
  },
  
  errorMessage: {
    fontFamily: 'System',
    fontSize: 13,
    fontWeight: '400',
    lineHeight: 18,
  },
  
  badge: {
    fontFamily: 'System',
    fontSize: 12,
    fontWeight: '500',
    lineHeight: 16,
  },
  
  tooltip: {
    fontFamily: 'System',
    fontSize: 13,
    fontWeight: '400',
    lineHeight: 18,
  },
  
  // ============ CONTACTS ============
  
  contactNamePrimary: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '600',
    lineHeight: 22,
  },
  
  contactNameList: {
    fontFamily: 'System',
    fontSize: 17,
    fontWeight: '400',
    lineHeight: 22,
  },
  
  userNameHeader: {
    fontFamily: 'System',
    fontSize: 22,
    fontWeight: '600',
    lineHeight: 28,
  },
  
  contactDetail: {
    fontFamily: 'System',
    fontSize: 15,
    fontWeight: '400',
    lineHeight: 20,
  },
};
```

### 7.3 Using Custom Fonts

If using custom fonts like Inter or Proxima Nova:

1. Add font files to: `ios/[ProjectName]/Resources/fonts/`
2. Update `Info.plist` with `UIAppFonts` array
3. Run: `cd ios && pod install`
4. Reference in styles: `fontFamily: 'Inter-Regular'`

**Required font files (example for Inter):**

```
ios/[ProjectName]/Resources/fonts/
├── Inter-Regular.ttf
├── Inter-Medium.ttf
├── Inter-SemiBold.ttf
└── Inter-Bold.ttf
```

**Info.plist configuration:**

```xml
<key>UIAppFonts</key>
<array>
  <string>Inter-Regular.ttf</string>
  <string>Inter-Medium.ttf</string>
  <string>Inter-SemiBold.ttf</string>
  <string>Inter-Bold.ttf</string>
</array>
```

> 📌 **Note:** Font file names must match exactly. Use `Inter-Regular.ttf`, `Inter-Bold.ttf` naming convention.

### 7.4 Dynamic Type Support

Implement Dynamic Type for accessibility compliance:

```typescript
// useDynamicType.ts

import { useWindowDimensions, PixelRatio } from 'react-native';

export const useDynamicType = () => {
  const { fontScale } = useWindowDimensions();
  
  const scaledFontSize = (baseSize: number, maxScale: number = 1.5): number => {
    const scaled = baseSize * fontScale;
    const maxSize = baseSize * maxScale;
    return Math.min(Math.round(scaled), maxSize);
  };
  
  const scaledLineHeight = (baseLineHeight: number, maxScale: number = 1.5): number => {
    const scaled = baseLineHeight * fontScale;
    const maxLineHeight = baseLineHeight * maxScale;
    return Math.min(Math.round(scaled), maxLineHeight);
  };
  
  return {
    fontScale,
    scaledFontSize,
    scaledLineHeight,
  };
};

// Usage example
const MyComponent = () => {
  const { scaledFontSize, scaledLineHeight } = useDynamicType();
  
  return (
    <Text style={{
      fontSize: scaledFontSize(17),
      lineHeight: scaledLineHeight(22),
    }}>
      Dynamic text that scales with user preferences
    </Text>
  );
};
```

### 7.5 Typography Component

Create a reusable Typography component:

```tsx
// Typography.tsx

import React from 'react';
import { Text, TextProps, TextStyle, StyleSheet } from 'react-native';
import { Typography as TypographyStyles } from './typography';
import { Colors } from './colors';

type TypographyVariant = keyof typeof TypographyStyles;

interface TypographyProps extends TextProps {
  variant?: TypographyVariant;
  color?: keyof typeof Colors.text;
  align?: TextStyle['textAlign'];
  children: React.ReactNode;
}

export const Typography: React.FC<TypographyProps> = ({
  variant = 'body',
  color = 'primary',
  align,
  style,
  children,
  ...props
}) => {
  return (
    <Text
      style={[
        TypographyStyles[variant],
        { color: Colors.text[color] },
        align && { textAlign: align },
        style,
      ]}
      {...props}
    >
      {children}
    </Text>
  );
};

// Usage
<Typography variant="title1" color="primary">
  Account Balance
</Typography>

<Typography variant="balanceLarge" color="primary">
  $12,345.67
</Typography>

<Typography variant="caption1" color="secondary">
  Last updated: 2 minutes ago
</Typography>
```

---

## 8. Accessibility Requirements

### 8.1 Minimum Font Sizes

| Content Type | Minimum Size |
|--------------|--------------|
| Body Text | 17pt (iOS standard) |
| Secondary Text | 15pt |
| Captions / Labels | 12pt (absolute minimum) |
| Tab Bar Labels | 10pt (iOS standard, with icons) |
| Touch Target Text | 44pt minimum touch area |

### 8.2 Color Contrast Requirements

| Content Type | Minimum Contrast Ratio |
|--------------|------------------------|
| Normal Text (< 18pt) | 4.5:1 (WCAG AA) |
| Large Text (≥ 18pt or 14pt bold) | 3:1 (WCAG AA) |
| Financial Data / Critical Info | 7:1 (WCAG AAA recommended) |

### 8.3 Dynamic Type Categories

Support these iOS Dynamic Type sizes for accessibility:

**Standard sizes:**
- xSmall, Small, Medium, Large (default), xLarge, xxLarge, xxxLarge

**Accessibility sizes:**
- AX1, AX2, AX3, AX4, AX5

> ⚠️ **Important:** Financial apps must support at least up to xxxLarge for regulatory compliance.

### 8.4 VoiceOver Considerations

```typescript
// Ensure proper accessibility labels for financial data
<Text 
  accessibilityLabel="Account balance: twelve thousand, three hundred forty-five dollars and sixty-seven cents"
  accessibilityRole="text"
>
  $12,345.67
</Text>

// Use accessibilityHint for additional context
<Text
  accessibilityLabel="Savings account"
  accessibilityHint="Double tap to view account details"
>
  Savings
</Text>
```

---

## 9. Typography Color Palette

| Color Name | Hex Value | RGB | Usage |
|------------|-----------|-----|-------|
| **Primary Text** | `#1F2937` | 31, 41, 55 | Headlines, body text |
| **Secondary Text** | `#4B5563` | 75, 85, 99 | Descriptions, subtitles |
| **Tertiary Text** | `#9CA3AF` | 156, 163, 175 | Placeholders, disabled |
| **Link / Action** | `#1A73E8` | 26, 115, 232 | Clickable text, CTAs |
| **Success** | `#10B981` | 16, 185, 129 | Positive amounts, confirmations |
| **Error** | `#EF4444` | 239, 68, 68 | Error messages, negative amounts |
| **Warning** | `#F59E0B` | 245, 158, 11 | Alerts, pending states |
| **White (on dark)** | `#FFFFFF` | 255, 255, 255 | Text on dark backgrounds |

### Color Constants

```typescript
// colors.ts

export const Colors = {
  text: {
    primary: '#1F2937',
    secondary: '#4B5563',
    tertiary: '#9CA3AF',
    disabled: '#D1D5DB',
    inverse: '#FFFFFF',
    link: '#1A73E8',
    success: '#10B981',
    error: '#EF4444',
    warning: '#F59E0B',
  },
  
  // Amount colors
  amount: {
    positive: '#10B981',  // Green for credits
    negative: '#EF4444',  // Red for debits
    neutral: '#1F2937',   // Black for balance
    pending: '#F59E0B',   // Yellow for pending
  },
};
```

---

## 10. Best Practices & Guidelines

### 10.1 ✅ Do's

- Use SF Pro system font for maximum compatibility and performance
- Maintain consistent hierarchy: Title > Headline > Body > Caption
- Use tabular figures for financial amounts to ensure alignment
- Support Dynamic Type for accessibility
- Use semibold for emphasis instead of bold when possible
- Keep line lengths between 50-75 characters for readability
- Use monospace fonts (SF Mono) for account numbers and codes
- Test typography at all Dynamic Type sizes
- Provide sufficient color contrast (4.5:1 minimum)
- Use proper accessibility labels for financial data

### 10.2 ❌ Don'ts

- Don't use more than 2 font families in the app
- Don't use font sizes below 11pt for any readable content
- Don't use light font weights for critical financial information
- Don't disable Dynamic Type scaling for body text
- Don't use decorative or script fonts for any UI elements
- Don't rely solely on color to convey meaning (accessibility)
- Don't use all-caps for long strings of text
- Don't mix proportional and tabular figures in the same number display
- Don't truncate financial amounts without clear indication
- Don't use justified text alignment (causes uneven spacing)

### 10.3 Financial Data Best Practices

```typescript
// ✅ GOOD: Proper financial formatting
<Text style={Typography.balanceLarge}>
  $12,345.67
</Text>

// ✅ GOOD: Use tabular figures for alignment
<Text style={{ fontVariant: ['tabular-nums'] }}>
  $1,234.56
  $  987.65
  $   12.34
</Text>

// ✅ GOOD: Clear positive/negative indication
<Text style={{ color: Colors.amount.positive }}>
  +$500.00
</Text>
<Text style={{ color: Colors.amount.negative }}>
  -$125.50
</Text>

// ❌ BAD: Truncated amounts
<Text numberOfLines={1} ellipsizeMode="tail">
  $12,345... // Never truncate financial data!
</Text>
```

---

## 11. Appendix

### 11.1 Resources & References

- **Apple Human Interface Guidelines:** [developer.apple.com/design/human-interface-guidelines/typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- **SF Pro Download:** [developer.apple.com/fonts/](https://developer.apple.com/fonts/)
- **Inter Font:** [fonts.google.com/specimen/Inter](https://fonts.google.com/specimen/Inter)
- **React Native Typography:** [reactnative.dev/docs/text](https://reactnative.dev/docs/text)
- **WCAG Guidelines:** [w3.org/WAI/WCAG21/quickref/](https://www.w3.org/WAI/WCAG21/quickref/)

### 11.2 Font Files Required (if using custom fonts)

| Font File | Weight | Usage |
|-----------|--------|-------|
| Inter-Regular.ttf | 400 | Body text |
| Inter-Medium.ttf | 500 | Slight emphasis |
| Inter-SemiBold.ttf | 600 | Headlines, buttons |
| Inter-Bold.ttf | 700 | Titles, balances |

### 11.3 Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                    TYPOGRAPHY QUICK REFERENCE               │
├─────────────────────────────────────────────────────────────┤
│  HEADINGS                                                   │
│  Large Title ........ SF Pro Display, 34pt, Bold           │
│  Title 1 ............ SF Pro Display, 28pt, Bold           │
│  Title 2 ............ SF Pro Display, 22pt, Bold           │
│  Headline ........... SF Pro Text, 17pt, Semibold          │
├─────────────────────────────────────────────────────────────┤
│  BODY                                                       │
│  Body ............... SF Pro Text, 17pt, Regular           │
│  Callout ............ SF Pro Text, 16pt, Regular           │
│  Subhead ............ SF Pro Text, 15pt, Regular           │
│  Caption ............ SF Pro Text, 12pt, Regular           │
├─────────────────────────────────────────────────────────────┤
│  FINANCIAL                                                  │
│  Balance (Large) .... SF Pro Display, 48pt, Bold           │
│  Balance (Medium) ... SF Pro Display, 34pt, Semibold       │
│  Transaction ........ SF Pro Text, 17pt, Medium            │
│  Account Number ..... SF Mono, 15pt, Regular               │
├─────────────────────────────────────────────────────────────┤
│  UI COMPONENTS                                              │
│  Primary Button ..... SF Pro Text, 17pt, Semibold          │
│  Text Field ......... SF Pro Text, 17pt, Regular           │
│  Tab Bar Label ...... SF Pro Text, 10pt, Medium            │
│  Error Message ...... SF Pro Text, 13pt, Regular (#EF4444) │
└─────────────────────────────────────────────────────────────┘
```

### 11.4 Contact for Clarification

For questions about these specifications or to obtain official OnePay brand guidelines:

- **Email:** socialsupport@onepay.com
- **Website:** [onepay.com](https://onepay.com)

---

*Document Version: 1.0*
*Last Updated: January 2026*
*Confidential - For Development Use Only*
