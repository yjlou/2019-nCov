
// Process the i18n initialization.
//
// If 'hl=' is set in URL, use that value. If not, use a trick to get user agent's preference.
//
// Callback is provided to update the i18n message after we know the language setting of the
// user agent.
//
function load_i18n(callback) {
  let lang = PARAMS.get("hl");
  let i18n = $.i18n();

  const supportedLanguages = ["en-US", "zh-TW", "ko", "he", "ja"];
  do {
    if (supportedLanguages.indexOf(lang) !== -1) break;
    if (supportedLanguages.indexOf(navigator.language) !== -1) {
      console.log('using navigator.language');
      lang = navigator.language;
      break;
    }
    for (let l of navigator.languages) {
      console.log(`checking ${l}`);
      if (supportedLanguages.indexOf(l) !== -1) {
        console.log('using navigator.languages');
        lang = l;
        break;
      }
    }
    if (lang) break;
    console.log('fallback to en-US');
    lang = "en-US";
  } while (0);
  console.log(`selected language: ${lang}`);
  HTML_LANG = lang;
  i18n.locale = lang;
  i18n.load( `locales/${lang}/text.json`, i18n.locale ).done(
    () => {
      callback();
    }
  );
}

function i18n_get_name(name) {
  if (typeof(name) === 'string') {
    return name;
  }
  if (HTML_LANG in name) {
    return name[HTML_LANG];
  }
  const supportedLanguages = ["en-US", "zh-TW", "ko", "he", "ja"];
  for (let lang of supportedLanguages) {
    if (name[lang]) return name[lang];
  }
  return 'No Name';
}

// Called after i18n .json file is loaded.
//
// This function iterates all elements starting with "HTML_" prefix. Then replace the
// innerHTML with i18n string (by its ID).
//
// It also does similar things for IMG.
//
function update_i18n_UI() {
  $("[id^=HTML_]").each(function(idx) {
    $(this).html($.i18n($(this)[0].id));
  });

  $("[id^=IMG_]").each(function(idx) {
    $(this).attr("src", $.i18n($(this)[0].id));
  });

  $("template").each(function(idx) {
    $(this.content).find('[id^=HTML_]').each(function(_) {
      $(this).html($.i18n($(this)[0].id));
    })
  });

  window.document.title = $.i18n("HTML_APP_NAME");
}

// Handle RTL UI.
//
// This must be run after the Materialize init
//
function apply_RTL_UI() {
  // Handle Right-to-Left languages
  let rtl = ['he', 'iw'];
  if (HTML_LANG && rtl.includes(HTML_LANG)) {
    // RTL
    $('html').children().css('direction', 'rtl');
    $('#nav-mobile').addClass('left');
    $('.btn_next_step').addClass('left');
    $('.select-dropdown').css('text-align', 'left');

    // Reverse the order of tabs.
    const tabs = $(".tabs")[0];
    const children = [...tabs.children].reverse();
    tabs.innerText = "";
    for (let c of children) {
      tabs.appendChild(c);
    }
  } else {
    // LTR
    $('html').children().css('direction', 'ltr');
    $('#nav-mobile').addClass('right');
    $('.btn_next_step').addClass('right');
  }
}
