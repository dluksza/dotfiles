function onebasket-local -d "Switch onebasket to local development packages"
    set -l ob_root "/Users/lock/workspace/stadion/onebasket-frontend-flutter/packages"
    set -l ws_root "/Users/lock/workspace/stadion/of-mobile/flutter"
    set -l patched 0

    for override in (find $ws_root -name "pubspec_overrides.yaml" -not -path "*/.dart_tool/*" 2>/dev/null)
        if not grep -q "onebasket_ui:" $override
            echo "  onebasket_ui:" >> $override
            echo "    path: $ob_root/onebasket_ui" >> $override
            echo "  onebasket_services:" >> $override
            echo "    path: $ob_root/onebasket_services" >> $override
            set patched (math $patched + 1)
        end
    end

    echo "Patched $patched pubspec_overrides.yaml files with local onebasket paths"
    echo "Run: cd $ws_root && melos exec -- flutter pub get"
end
