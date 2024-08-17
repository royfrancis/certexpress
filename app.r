## certexpress
## R shinyapp to generate course certificates
## 2024 Roy Francis

library(shiny)
library(bslib)
library(quarto)
library(markdown)

source("functions.r")

## ui --------------------------------------------------------------------------

ui <- page_fluid(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  theme = bs_theme(preset = "lux"),
  lang = "en",
  title = "CertExpress",
  card(
    full_screen = TRUE,
    card_header(
      class = "app-card-header",
      tags$div(
        class = "app-header",
        span(tags$h5("CertExpress", style = "margin:0px;color:silver;"), style = "vertical-align:middle;display:inline-block;")
      )
    ),
    layout_sidebar(
      sidebar = sidebar(
        width = 300,
        tooltip(
          textAreaInput("in_names", "Participants", value = txt_names, resize = "vertical", width = "100%"),
          "Participant name(s). Add one name per row",
          placement = "right"
        ),
        textAreaInput("in_content", "Body text", value = txt_content, height = "300px"),
        popover(
          div(class = "help-note", HTML("<span><i class='fa fa-circle-info'></i></span><span style='margin-left:5px;'>Style text using markdown</span>")),
          includeMarkdown("help.md"),
          title = "Markdown formatting"
        ),
        uiOutput("ui_sign"),
        textAreaInput("in_teacher", "Teacher", value = txt_teacher),
        textAreaInput("in_footnotes", "Footnotes", value = txt_footnotes),
        hr(),
        tooltip(actionButton("btn_update", "Update", class = "btn-large"), "Preview changes", placement = "top"),
        layout_columns(
          style = "margin-top:5px;",
          tooltip(actionButton("btn_reset", "Reset", class = "btn-warning"), "Reset all inputs", placement = "bottom"),
          tooltip(downloadButton("btn_download", "Download"), "Download PDFs as a zip file", placement = "bottom"),
          col_widths = c(4, 8)
        )
      ),
      uiOutput("out_pdf", width = "100%", height = "100%")
    ),
    card_footer(
      class = "app-footer",
      div(
        class = "help-note",
        paste0(format(Sys.time(), "%Y"), " Roy Francis • Version: ", fn_version()),
        HTML("• <a href='https://github.com/royfrancis/certexpress' target='_blank'><i class='fab fa-github'></i></a> • <a href='mailto:zydoosu@gmail.com' target='_blank'><i class='fa fa-envelope'></i></a>")
      )
    )
  )
)

## -----------------------------------------------------------------------------
## server ----------------------------------------------------------------------

server <- function(session, input, output) {
  ## content block -------------------------------------------------------------
  ## create temporary directory

  temp_dir <- tempdir(check = TRUE)
  temp_id <- paste(sample(letters, 10), collapse = "")
  temp_dir_active <- file.path(temp_dir, temp_id)
  cat(paste0("Working directory: ", temp_dir_active, "\n"))
  store <- reactiveValues(wd = temp_dir_active, id = temp_id, sign_path = NULL)
  if (!dir.exists(temp_dir_active)) dir.create(temp_dir_active)
  if (!dir.exists(file.path(temp_dir_active, "render"))) dir.create(file.path(temp_dir_active, "render"))
  copy_dirs(temp_dir_active)
  addResourcePath(temp_id, temp_dir_active)

  ## FN: fn_sign ---------------------------------------------------------------
  ## function to get sign

  fn_sign <- reactive({
    validate(fn_validate_im(input$in_sign))

    if (is.null(input$in_sign)) {
      store$sign_path <- NULL
    } else {
      ext <- tools::file_ext(input$in_sign$datapath)
      new_name <- paste0("sign.", ext)
      if (file.exists(file.path(store$wd, new_name))) file.remove(file.path(store$wd, new_name))
      file.copy(input$in_sign$datapath, file.path(store$wd, new_name))
      store$sign_path <- list(path = new_name)
    }
  })

  ## FN: fn_vars ---------------------------------------------------------------
  ## function to get meta variables

  fn_vars <- reactive({
    # if values are available, use them, else use defaults
    validate(need(input$in_names, message = "Participants is empty. Enter one or more names."))
    v_names <- unique(unlist(strsplit(input$in_names, "\n")))
    v_content <- input$in_content
    v_teacher <- input$in_teacher
    v_footnotes <- input$in_footnotes
    fn_sign()

    if (is.null(input$in_sign_height)) {
      v_sign_height <- "15mm"
    } else {
      v_sign_height <- paste0(input$in_sign_height, "mm")
    }

    return(list(
      names = v_names, content = v_content, "sign-image" = store$sign_path,
      "sign-height" = v_sign_height, teacher = v_teacher, footnotes = v_footnotes,
      version = fn_version()
    ))
  })

  ## ER: Update button binding -------------------------------------------------

  evr_update <- eventReactive(input$btn_update, {
    return(fn_vars())
  })

  ## FN: fn_build -------------------------------------------------------------
  ## function to create preview pdf

  fn_build <- reactive({
    vars <- evr_update()
    validate(fn_validate(vars))

    vars["participant"] <- vars$names[1]

    progress_plot <- shiny::Progress$new()
    progress_plot$set(message = "Creating PDF ...", value = 0.1)

    output_file <- "index.pdf"
    ppath <- store$wd
    if (file.exists(file.path(ppath, output_file))) file.remove(file.path(ppath, output_file))
    quarto::quarto_render(input = file.path(ppath, "index.qmd"), metadata = vars)

    progress_plot$set(message = "Completed", value = 1)
    progress_plot$close()
  })

  ## OUT: out_pdf -------------------------------------------------------------
  ## plots figure

  output$out_pdf <- renderUI({
    if (input$btn_update == 0) {
      return(div(p("Click 'Update' to generate preview.")))
    } else {
      fn_build()
      return(tags$iframe(src = file.path(store$id, "index.pdf"), height = "100%", width = "100%"))
    }
  })

  ## FN: fn_download -----------------------------------------------------------
  ## function to download a zipped file with images

  fn_download <- function() {
    vars <- fn_vars()

    # render path
    rpath <- file.path(store$wd, "render")
    if (!dir.exists(rpath)) dir.create(rpath)

    progress_download <- shiny::Progress$new()
    progress_download$set(message = "Starting...", value = 0.1)

    names <- vars$names
    len <- length(names)
    for (i in seq_along(names)) {
      name <- names[i]
      vars["participant"] <- name
      fname <- paste0(tolower(gsub(" ", "-", name)), ".pdf")

      if (exists(file.path(store$wd, "index.pdf"))) file.remove(file.path(store$wd, "index.pdf"))
      quarto::quarto_render(input = file.path(store$wd, "index.qmd"), metadata = vars)
      file.rename(file.path(store$wd, "index.pdf"), file.path(store$wd, "render", fname))

      progress_download$set(value = round(i / len, 1) - 0.1, message = paste0("Creating PDFs (", i, "/", len, ") ..."))
    }

    cpath <- file.path(rpath, "certificates.zip")
    if (exists(cpath)) unlink(cpath)

    progress_download$set(value = 0.95, message = "Zipping PDFs ...")

    zip(cpath, files = list.files(path = rpath, pattern = "pdf", full.names = TRUE), flags = "-r9Xj")
    unlink(list.files(path = rpath, pattern = "pdf", full.names = TRUE))

    progress_download$set(message = "Completed", value = 1)
    progress_download$close()
  }

  ## DHL: btn_download ---------------------------------------------------------
  ## download handler for downloading zipped file

  output$btn_download <- downloadHandler(
    filename = "certificates.zip",
    content = function(file) {
      fn_download()
      cpath <- file.path(store$wd, "render", "certificates.zip")
      file.copy(cpath, file, overwrite = T)
      unlink(cpath)
    }
  )

  ## OBS: btn_reset ------------------------------------------------------------
  ## observer for reset

  observeEvent(input$btn_reset, {
    updateTextAreaInput(session, "in_names", "Participants", value = txt_names)
    updateTextAreaInput(session, "in_content", "Body text", value = txt_content)
    updateTextAreaInput(session, "in_teacher", "Teacher", value = txt_teacher)
    updateTextAreaInput(session, "in_footnotes", "Footnotes", value = txt_footnotes)
    # updateSelectInput(session, "in_design", "Design", choices = c("Folium", "Plain"), selected = "Folium")
    store$sign_path <- NULL
  })

  ## UI ----------- ------------------------------------------------------------
  ## render ui for sign upload and sign state

  output$ui_sign <- renderUI({
    input$btn_reset
    div(
      tooltip(
        fileInput("in_sign", "Signature", multiple = FALSE, accept = c("image/png", "image/jpeg", "image/tiff", "image/gif"), width = "100%", placeholder = "Upload signature"),
        "Use a PNG with transparent background.",
        placement = "right"
      ),
      sliderInput("in_sign_height", "Signature height", min = 5, max = 40, step = 1, value = 15)
    )
  })

  ## OSE -----------------------------------------------------------------------
  ## delete user directory when session ends

  session$onSessionEnded(function() {
    cat(paste0("Removing working directory: ", isolate(store$wd), " ...\n"))
    if (dir.exists(isolate(store$wd))) {
      unlink(isolate(store$wd), recursive = TRUE)
    }
  })
}
## launch ----------------------------------------------------------------------

shinyApp(ui = ui, server = server)
