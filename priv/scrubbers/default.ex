defmodule Pleroma.HTML.Scrubber.Default do
  @doc "The default HTML scrubbing policy: no "

  require FastSanitize.Sanitizer.Meta
  alias FastSanitize.Sanitizer.Meta

  # credo:disable-for-previous-line
  # No idea how to fix this one…

  @valid_schemes Pleroma.Config.get([:uri_schemes, :valid_schemes], [])

  Meta.strip_comments()

  Meta.allow_tag_with_uri_attributes(:a, ["href", "data-user", "data-tag"], @valid_schemes)

  Meta.allow_tag_with_this_attribute_values(:a, "class", [
    "hashtag",
    "u-url",
    "mention",
    "u-url mention",
    "mention u-url"
  ])

  Meta.allow_tag_with_this_attribute_values(:a, "rel", [
    "tag",
    "nofollow",
    "noopener",
    "noreferrer",
    "ugc"
  ])

  Meta.allow_tag_with_these_attributes(:a, ["name", "title"])

  Meta.allow_tag_with_these_attributes(:abbr, ["title"])

  Meta.allow_tag_with_these_attributes(:b, [])
  Meta.allow_tag_with_these_attributes(:blockquote, [])
  Meta.allow_tag_with_these_attributes(:br, [])
  Meta.allow_tag_with_these_attributes(:code, [])
  Meta.allow_tag_with_these_attributes(:del, [])
  Meta.allow_tag_with_these_attributes(:em, [])
  Meta.allow_tag_with_these_attributes(:hr, [])
  Meta.allow_tag_with_these_attributes(:i, [])
  Meta.allow_tag_with_these_attributes(:li, [])
  Meta.allow_tag_with_these_attributes(:ol, [])
  Meta.allow_tag_with_these_attributes(:p, [])
  Meta.allow_tag_with_these_attributes(:pre, [])
  Meta.allow_tag_with_these_attributes(:strong, [])
  Meta.allow_tag_with_these_attributes(:sub, [])
  Meta.allow_tag_with_these_attributes(:sup, [])
  Meta.allow_tag_with_these_attributes(:ruby, [])
  Meta.allow_tag_with_these_attributes(:rb, [])
  Meta.allow_tag_with_these_attributes(:rp, [])
  Meta.allow_tag_with_these_attributes(:rt, [])
  Meta.allow_tag_with_these_attributes(:rtc, [])
  Meta.allow_tag_with_these_attributes(:u, [])
  Meta.allow_tag_with_these_attributes(:ul, [])

  Meta.allow_tag_with_this_attribute_values(:span, "class", [
    "h-card",
    "quote-inline",
    "mfm",
    "mfm _mfm_tada_",
    "mfm _mfm_jelly_",
    "mfm _mfm_twitch_",
    "mfm _mfm_shake_",
    "mfm _mfm_spin_",
    "mfm _mfm_jump_",
    "mfm _mfm_bounce_",
    "mfm _mfm_flip_",
    "mfm _mfm_x2_",
    "mfm _mfm_x3_",
    "mfm _mfm_x4_",
    "mfm _mfm_blur_",
    "mfm _mfm_rainbow_",
    "mfm _mfm_rotate_"
  ])

  Meta.allow_tag_with_these_attributes(:span, [
    "data-x",
    "data-y",
    "data-h",
    "data-v",
    "data-left",
    "data-right"
  ])

  Meta.allow_tag_with_this_attribute_values(:code, "class", ["inline"])

  @allow_inline_images Pleroma.Config.get([:markup, :allow_inline_images])

  if @allow_inline_images do
    # restrict img tags to http/https only, because of MediaProxy.
    Meta.allow_tag_with_uri_attributes(:img, ["src"], ["http", "https"])

    Meta.allow_tag_with_these_attributes(:img, [
      "width",
      "height",
      "title",
      "alt"
    ])
  end

  if Pleroma.Config.get([:markup, :allow_tables]) do
    Meta.allow_tag_with_these_attributes(:table, [])
    Meta.allow_tag_with_these_attributes(:tbody, [])
    Meta.allow_tag_with_these_attributes(:td, [])
    Meta.allow_tag_with_these_attributes(:th, [])
    Meta.allow_tag_with_these_attributes(:thead, [])
    Meta.allow_tag_with_these_attributes(:tr, [])
  end

  if Pleroma.Config.get([:markup, :allow_headings]) do
    Meta.allow_tag_with_these_attributes(:h1, [])
    Meta.allow_tag_with_these_attributes(:h2, [])
    Meta.allow_tag_with_these_attributes(:h3, [])
    Meta.allow_tag_with_these_attributes(:h4, [])
    Meta.allow_tag_with_these_attributes(:h5, [])
  end

  if Pleroma.Config.get([:markup, :allow_fonts]) do
    Meta.allow_tag_with_these_attributes(:font, ["face"])
  end

  if Pleroma.Config.get([:markup, :allow_math]) do
    Meta.allow_tag_with_these_attributes("annotation", ["encoding"])
    Meta.allow_tag_with_these_attributes(:"annotation-xml", ["encoding"])
    Meta.allow_tag_with_these_attributes("maction", ["mathvariant", "displaystyle", "scriptlevel"])

    Meta.allow_tag_with_these_attributes(:math, [
      "display",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("merror", ["mathvariant", "displaystyle", "scriptlevel"])

    Meta.allow_tag_with_these_attributes("mfrac", [
      "linethickness",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes(:mi, ["mathvariant", "displaystyle", "scriptlevel"])

    Meta.allow_tag_with_these_attributes("mmultiscripts", [
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes(:mn, ["mathvariant", "displaystyle", "scriptlevel"])

    Meta.allow_tag_with_these_attributes(:mo, [
      "form",
      "stretchy",
      "symmetric",
      "largeop",
      "movablelimits",
      "lspace",
      "rspace",
      "minsize",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("mover", [
      "accent",
      "accentunder",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("mpadded", [
      "width",
      "height",
      "depth",
      "lspace",
      "voffset",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("mphantom", ["mathvariant", "displaystyle", "scriptlevel"])

    Meta.allow_tag_with_these_attributes("mprescripts", [
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("mroot", ["mathvariant", "displaystyle", "scriptlevel"])
    Meta.allow_tag_with_these_attributes("mrow", ["mathvariant", "displaystyle", "scriptlevel"])
    Meta.allow_tag_with_these_attributes("ms", ["mathvariant", "displaystyle", "scriptlevel"])

    Meta.allow_tag_with_these_attributes("mspace", [
      "width",
      "height",
      "depth",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("msqrt", ["mathvariant", "displaystyle", "scriptlevel"])
    Meta.allow_tag_with_these_attributes("mstyle", ["mathvariant", "displaystyle", "scriptlevel"])
    Meta.allow_tag_with_these_attributes("msub", ["mathvariant", "displaystyle", "scriptlevel"])
    Meta.allow_tag_with_these_attributes("msubsup", ["mathvariant", "displaystyle", "scriptlevel"])
    Meta.allow_tag_with_these_attributes("msup", ["mathvariant", "displaystyle", "scriptlevel"])
    Meta.allow_tag_with_these_attributes("mtable", ["mathvariant", "displaystyle", "scriptlevel"])

    Meta.allow_tag_with_these_attributes("mtd", [
      "columnspan",
      "rowspan",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("mtext", ["mathvariant", "displaystyle", "scriptlevel"])
    Meta.allow_tag_with_these_attributes("mtr", ["mathvariant", "displaystyle", "scriptlevel"])

    Meta.allow_tag_with_these_attributes("munder", [
      "accent",
      "accentunder",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("munderover", [
      "accent",
      "accentunder",
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])

    Meta.allow_tag_with_these_attributes("semantics", [
      "mathvariant",
      "displaystyle",
      "scriptlevel"
    ])
  end

  Meta.allow_tag_with_these_attributes(:center, [])
  Meta.allow_tag_with_these_attributes(:small, [])

  Meta.strip_everything_not_covered()

  defp scrub_css(value), do: value
end
