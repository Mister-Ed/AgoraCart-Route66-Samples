// Javascript snippets for AgoraCart Manager areas.

// trigger - tooltip feature in mgr screens for inline info/doc features.
$(document).ready(function(){
    $('[data-toggle="tooltip"]').tooltip();
});

// trigger - pop over feature in mgr screens for inline info/doc features.
$(document).ready(function(){
    $('[data-toggle="popover"]').popover();
});

// BEGIN: triggers that control default tabs in various manager screens
// Default is first tab, but sometimes we want other tabs shown for a particular mgr screen.
// Tabs allow us to create shorter mgr screens without losing all the legacy feature groupings.
$(function () {
    $('#tabs a[href="#tabs-5"]').tab('show')
})
$(function () {
    $('#tabs2 a[href="#tabs-1"]').tab('show')
})
$(function () {
    $('#tabs3 a[href="#tabs-1"]').tab('show')
})
$(function () {
    $('#tabs4 a[href="#tabs-1"]').tab('show')
})
$(function () {
    $('#tabs6 a[href="#tabs-1"]').tab('show')
})
$(document).ready(function () {
    $('#deletePageModal').modal('show');
});
// END: triggers that control default tabs in various manager screens


// BEGIN: sortables for changing order of widgets or links.

// Each sortable on a mgr page or tab within a mgr screen needs its own function.
// New feature in Route66+ allowing sorting in the online mgr and storing the
// preferred order without changing static templates (HTML code) directly.
// Each template can support up to 9 zones/areas to place widgets that can be sorted.
$(function() {
    $("#sortable-4").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order = $(this).sortable('toArray');
           $('#newOrder').val(Order.join(','));
           //alert($('#newOrder').val());
        }
    });
        $( "#sortable-4" ).disableSelection();
});

$(function() {
    $("#sortable-Zone1").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order1 = $(this).sortable('toArray');
           $('#newOrderZone1').val(Order1.join(','));
        }
    });
        $( "#sortable-Zone1" ).disableSelection();
});

$(function() {
    $("#sortable-Zone2").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order2 = $(this).sortable('toArray');
           $('#newOrderZone2').val(Order2.join(','));
        }
    });
        $( "#sortable-Zone2" ).disableSelection();
});

$(function() {
    $("#sortable-Zone3").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order3 = $(this).sortable('toArray');
           $('#newOrderZone3').val(Order3.join(','));
        }
    });
        $( "#sortable-Zone3" ).disableSelection();
});

$(function() {
    $("#sortable-Zone4").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order4 = $(this).sortable('toArray');
           $('#newOrderZone4').val(Order4.join(','));
        }
    });
        $( "#sortable-Zone4" ).disableSelection();
});

$(function() {
    $("#sortable-Zone5").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order5 = $(this).sortable('toArray');
           $('#newOrderZone5').val(Order5.join(','));
        }
    });
        $( "#sortable-Zone5" ).disableSelection();
});

$(function() {
    $("#sortable-Zone6").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order6 = $(this).sortable('toArray');
           $('#newOrderZone6').val(Order6.join(','));
        }
    });
        $( "#sortable-Zone6" ).disableSelection();
});

$(function() {
    $("#sortable-Zone7").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order7 = $(this).sortable('toArray');
           $('#newOrderZone7').val(Order7.join(','));
        }
    });
        $( "#sortable-Zone7" ).disableSelection();
});

$(function() {
    $("#sortable-Zone8").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order8 = $(this).sortable('toArray');
           $('#newOrderZone8').val(Order8.join(','));
        }
    });
        $( "#sortable-Zone8" ).disableSelection();
});

$(function() {
    $("#sortable-Zone9").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var Order9 = $(this).sortable('toArray');
           $('#newOrderZone9').val(Order9.join(','));
        }
    });
        $( "#sortable-Zone9" ).disableSelection();
});

$(function() {
    $("#sortable-ZoneHome").sortable({
        placeholder: "highlight",
        axis: "y",
        opacity: 0.5,
        tolerance: "pointer",
        zIndex: 9999,
        cursor: "move",
        update: function(event, ui) {
           var OrderHome = $(this).sortable('toArray');
           $('#newOrderZoneHome').val(OrderHome.join(','));
        }
    });
        $( "#sortable-ZoneHome" ).disableSelection();
});
// END: sortables for changing order of widgets or links.


// BEGIN: disables back button in mgr screens, if enabled
history.pushState(null, document.title, location.href);
window.addEventListener('popstate', function (event)
{
  history.pushState(null, document.title, location.href);
});

(function (global) {

    if(typeof (global) === "undefined") {
        throw new Error("window is undefined");
    }

    var _hash = "!";
    var noBackPlease = function () {
        global.location.href += "#";

        // making sure we have the fruit available for juice (^__^)
        global.setTimeout(function () {
            global.location.href += "!";
        }, 50);
    };

    global.onhashchange = function () {
        if (global.location.hash !== _hash) {
            global.location.hash = _hash;
        }
    };

    global.onload = function () {
        noBackPlease();

        // disables backspace on page except on input fields and textarea..
        document.body.onkeydown = function (e) {
            var elm = e.target.nodeName.toLowerCase();
            if (e.which === 8 && (elm !== 'input' && elm  !== 'textarea')) {
                e.preventDefault();
            }
            // stopping event bubbling up the DOM tree..
            e.stopPropagation();
        };
    }

})(window);
// END: disables back button in mgr screens, if enabled
