% Keeping for backwards compatibility

function rebuild_libs()
  % notify that this function is deprecated
  warning('This function is deprecated. Use build instead.');

  build();
end