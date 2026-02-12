package controller;

import annotation.controllerAnnotation;
import annotation.Get;
import annotation.Post;
import annotation.requestParam;
import model.ModelView;
import model.Vehicule;
import dao.VehiculeDao;

import java.util.ArrayList;
import java.util.List;

@controllerAnnotation
public class VehiculeController {

    @Get("/vehicules")
    public ModelView list() {
        ModelView mv = new ModelView("/WEB-INF/views/vehiculeList.jsp");
        try {
            VehiculeDao dao = new VehiculeDao();
            mv.addData("vehicules", dao.findAll());
        } catch (Exception e) {
            mv.addData("error", "Erreur chargement véhicules: " + e.getMessage());
            mv.addData("vehicules", new ArrayList<Vehicule>());
        }
        return mv;
    }

    @Get("/vehicules/add")
    public ModelView showAddForm() {
        return new ModelView("/WEB-INF/views/vehiculeForm.jsp");
    }

    @Post("/vehicules/add")
    public ModelView add(
            @requestParam("reference") String reference,
            @requestParam("nbrPlace") int nbrPlace,
            @requestParam("typeCarburant") String typeCarburant) {

        ModelView mv = new ModelView("/WEB-INF/views/vehiculeForm.jsp");
        try {
            Vehicule v = new Vehicule();
            v.setReference(reference);
            v.setNbrPlace(nbrPlace);
            v.setTypeCarburant(typeCarburant);

            VehiculeDao dao = new VehiculeDao();
            dao.insert(v);
            mv.addData("success", "Véhicule ajouté");
        } catch (Exception e) {
            mv.addData("error", "Erreur ajout véhicule: " + e.getMessage());
        }
        return mv;
    }

    @Get("/vehicules/edit")
    public ModelView showEditForm(@requestParam("id") int id) {
        ModelView mv = new ModelView("/WEB-INF/views/vehiculeForm.jsp");
        try {
            VehiculeDao dao = new VehiculeDao();
            mv.addData("vehicule", dao.findById(id));
        } catch (Exception e) {
            mv.addData("error", "Erreur chargement véhicule: " + e.getMessage());
        }
        return mv;
    }

    @Post("/vehicules/update")
    public ModelView update(
            @requestParam("id") int id,
            @requestParam("reference") String reference,
            @requestParam("nbrPlace") int nbrPlace,
            @requestParam("typeCarburant") String typeCarburant) {

        ModelView mv = new ModelView("/WEB-INF/views/vehiculeForm.jsp");
        try {
            Vehicule v = new Vehicule(id, reference, nbrPlace, typeCarburant);
            VehiculeDao dao = new VehiculeDao();
            dao.update(v);
            mv.addData("success", "Véhicule mis à jour");
            mv.addData("vehicule", v);
        } catch (Exception e) {
            mv.addData("error", "Erreur mise à jour véhicule: " + e.getMessage());
        }
        return mv;
    }

    @Post("/vehicules/delete")
    public ModelView delete(@requestParam("id") int id) {
        ModelView mv = new ModelView("/WEB-INF/views/vehiculeList.jsp");
        try {
            VehiculeDao dao = new VehiculeDao();
            dao.delete(id);
            mv.addData("success", "Véhicule supprimé");
            mv.addData("vehicules", dao.findAll());
        } catch (Exception e) {
            mv.addData("error", "Erreur suppression véhicule: " + e.getMessage());
            mv.addData("vehicules", new ArrayList<Vehicule>());
        }
        return mv;
    }
}