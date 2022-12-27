RegisterNUICallback('formCreateEntity_preview.filterModels.inspected.objects',
                    function()
    local models = {}
    for model in pairs(Editor.GetInspectedObjectModels()) do
        table.insert(models, model)
    end
    NUI.Call('formCreateEntity_preview.listInspectedModels',
             {dumpName = 'objects', models = models})
end)
