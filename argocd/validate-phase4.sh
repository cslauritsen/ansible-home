#!/usr/bin/env bash
# Phase 4 Validation Script
# Validates ArgoCD application manifests before deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/applications"
ROOT_APP="${SCRIPT_DIR}/app-of-apps/root-app.yaml"

echo "🔍 Validating ArgoCD Application Manifests (Phase 4)"
echo "=================================================="
echo ""

# Check if directories exist
if [ ! -d "$APP_DIR" ]; then
    echo "❌ Applications directory not found: $APP_DIR"
    exit 1
fi

if [ ! -f "$ROOT_APP" ]; then
    echo "❌ Root app not found: $ROOT_APP"
    exit 1
fi

echo "✅ Directory structure exists"
echo ""

# Count application files
APP_COUNT=$(find "$APP_DIR" -type f -name "*.yaml" | wc -l | tr -d ' ')
echo "📊 Found $APP_COUNT application manifests"
echo ""

# Validate YAML syntax
echo "🔧 Validating YAML syntax..."
YAML_ERRORS=0

for file in "$APP_DIR"/*.yaml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        if command -v yq &> /dev/null; then
            if yq eval '.' "$file" > /dev/null 2>&1; then
                echo "  ✅ $filename"
            else
                echo "  ❌ $filename - Invalid YAML"
                YAML_ERRORS=$((YAML_ERRORS + 1))
            fi
        else
            # Fallback to basic validation without yq
            if grep -q "apiVersion:" "$file" && grep -q "kind: Application" "$file"; then
                echo "  ✅ $filename (basic check)"
            else
                echo "  ❌ $filename - Missing required fields"
                YAML_ERRORS=$((YAML_ERRORS + 1))
            fi
        fi
    fi
done

# Validate root app
if command -v yq &> /dev/null; then
    if yq eval '.' "$ROOT_APP" > /dev/null 2>&1; then
        echo "  ✅ root-app.yaml"
    else
        echo "  ❌ root-app.yaml - Invalid YAML"
        YAML_ERRORS=$((YAML_ERRORS + 1))
    fi
else
    if grep -q "apiVersion:" "$ROOT_APP" && grep -q "kind: Application" "$ROOT_APP"; then
        echo "  ✅ root-app.yaml (basic check)"
    else
        echo "  ❌ root-app.yaml - Missing required fields"
        YAML_ERRORS=$((YAML_ERRORS + 1))
    fi
fi

echo ""

# Check for required fields
echo "🔧 Checking required fields in applications..."
FIELD_ERRORS=0

for file in "$APP_DIR"/*.yaml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")

        # Check for required fields
        if ! grep -q "repoURL:" "$file"; then
            echo "  ❌ $filename - Missing repoURL"
            FIELD_ERRORS=$((FIELD_ERRORS + 1))
        elif ! grep -q "targetRevision:" "$file"; then
            echo "  ❌ $filename - Missing targetRevision"
            FIELD_ERRORS=$((FIELD_ERRORS + 1))
        elif ! grep -q "path: helmfile/" "$file"; then
            echo "  ❌ $filename - Missing or invalid path"
            FIELD_ERRORS=$((FIELD_ERRORS + 1))
        elif ! grep -q "plugin:" "$file" || ! grep -q "name: helmfile" "$file"; then
            echo "  ❌ $filename - Missing helmfile plugin configuration"
            FIELD_ERRORS=$((FIELD_ERRORS + 1))
        else
            echo "  ✅ $filename"
        fi
    fi
done

echo ""

# Check repository URL consistency
echo "🔧 Checking repository URL consistency..."
REPO_URL=$(grep "repoURL:" "$ROOT_APP" | head -1 | awk '{print $2}')
echo "  Expected: $REPO_URL"

INCONSISTENT=0
for file in "$APP_DIR"/*.yaml "$ROOT_APP"; do
    if [ -f "$file" ]; then
        FILE_REPO_URL=$(grep "repoURL:" "$file" | head -1 | awk '{print $2}')
        if [ "$FILE_REPO_URL" != "$REPO_URL" ]; then
            filename=$(basename "$file")
            echo "  ❌ $filename has different repo URL: $FILE_REPO_URL"
            INCONSISTENT=$((INCONSISTENT + 1))
        fi
    fi
done

if [ $INCONSISTENT -eq 0 ]; then
    echo "  ✅ All applications use consistent repo URL"
fi

echo ""

# Summary
echo "=================================================="
echo "📋 Validation Summary"
echo "=================================================="
echo "Total Applications: $APP_COUNT"
echo "YAML Syntax Errors: $YAML_ERRORS"
echo "Field Errors: $FIELD_ERRORS"
echo "Inconsistent Repo URLs: $INCONSISTENT"
echo ""

TOTAL_ERRORS=$((YAML_ERRORS + FIELD_ERRORS + INCONSISTENT))

if [ $TOTAL_ERRORS -eq 0 ]; then
    echo "✅ All validations passed!"
    echo ""
    echo "📝 Next Steps:"
    echo "  1. Review README-APPLICATIONS.md for deployment instructions"
    echo "  2. Complete Phase 5 (Convert secrets to sealed secrets)"
    echo "  3. Deploy root application: kubectl apply -f $ROOT_APP"
    echo ""
    exit 0
else
    echo "❌ Found $TOTAL_ERRORS error(s). Please fix before proceeding."
    echo ""
    exit 1
fi

