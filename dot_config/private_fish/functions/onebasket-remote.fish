function onebasket-remote -d "Switch onebasket to published OnePub packages"
    set -l ws_root ~/workspace/stadion/of-mobile/flutter
    set -l cleaned 0

    for override in (find $ws_root -name "pubspec_overrides.yaml" -not -path "*/.dart_tool/*" 2>/dev/null)
        if grep -q onebasket $override
            grep -v onebasket $override >"$override.tmp"
            mv "$override.tmp" $override
            set cleaned (math $cleaned + 1)
        end
    end

    echo "Cleaned onebasket overrides from $cleaned pubspec_overrides.yaml files"
    echo "Run: cd $ws_root && melos exec -- flutter pub get"
end
